from __future__ import annotations

import sqlite3

from config import Config
from db import connect_db


def has_column(conn: sqlite3.Connection, table: str, column: str) -> bool:
    return any(row[1] == column for row in conn.execute(f"PRAGMA table_info({table})"))


def migrate(conn: sqlite3.Connection) -> None:
    conn.execute("PRAGMA foreign_keys = ON")

    if not has_column(conn, "notification", "expires_at"):
        conn.execute("ALTER TABLE notification ADD COLUMN expires_at TEXT")

    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS semester (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            semester_code TEXT NOT NULL UNIQUE,
            semester_name TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            status INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0, 1)),
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            CHECK (end_date >= start_date)
        );

        CREATE TABLE IF NOT EXISTS leave_request_course (
            leave_request_id INTEGER NOT NULL,
            course_id INTEGER NOT NULL,
            PRIMARY KEY (leave_request_id, course_id),
            FOREIGN KEY (leave_request_id) REFERENCES leave_request(id)
                ON UPDATE CASCADE ON DELETE CASCADE,
            FOREIGN KEY (course_id) REFERENCES course(id)
                ON UPDATE CASCADE ON DELETE RESTRICT
        );

        CREATE TABLE IF NOT EXISTS room_booking_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            booking_id INTEGER NOT NULL,
            operator_id INTEGER,
            action TEXT NOT NULL CHECK (
                action IN ('SUBMIT', 'UPDATE', 'APPROVE', 'REJECT', 'CANCEL', 'FINISH')
            ),
            old_status TEXT,
            new_status TEXT,
            remark TEXT,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (booking_id) REFERENCES room_booking(id)
                ON UPDATE CASCADE ON DELETE CASCADE,
            FOREIGN KEY (operator_id) REFERENCES sys_user(id)
                ON UPDATE CASCADE ON DELETE SET NULL
        );

        CREATE INDEX IF NOT EXISTS idx_semester_dates
        ON semester(start_date, end_date, status);

        CREATE INDEX IF NOT EXISTS idx_leave_request_applicant_status
        ON leave_request(applicant_id, status, created_at);

        CREATE INDEX IF NOT EXISTS idx_leave_request_course_course
        ON leave_request_course(course_id, leave_request_id);

        CREATE INDEX IF NOT EXISTS idx_schedule_change_applicant_status
        ON schedule_change(applicant_id, status, created_at);

        CREATE INDEX IF NOT EXISTS idx_schedule_change_schedule_week
        ON schedule_change(schedule_id, new_week, status);

        CREATE INDEX IF NOT EXISTS idx_room_booking_log_booking
        ON room_booking_log(booking_id, created_at);

        CREATE INDEX IF NOT EXISTS idx_notification_expires
        ON notification(status, expires_at);
        """
    )

    # 原触发器把单周课与双周课也可能误判为冲突。这里替换为考虑周类型的版本。
    conn.executescript(
        """
        DROP TRIGGER IF EXISTS trg_enrollment_insert_validate;
        DROP TRIGGER IF EXISTS trg_enrollment_update_validate;

        CREATE TRIGGER trg_enrollment_insert_validate
        BEFORE INSERT ON course_enrollment
        FOR EACH ROW
        WHEN NEW.status = 'SELECTED'
        BEGIN
            SELECT CASE
                WHEN NOT EXISTS (
                    SELECT 1 FROM sys_user
                    WHERE id = NEW.student_id
                      AND role = 'STUDENT'
                      AND status = 1
                )
                THEN RAISE(ABORT, '只有正常学生账号可以选课')
            END;

            SELECT CASE
                WHEN NOT EXISTS (
                    SELECT 1 FROM course
                    WHERE id = NEW.course_id
                      AND status = 1
                      AND selection_status = 'OPEN'
                      AND datetime('now') >= datetime(selection_start)
                      AND datetime('now') <= datetime(selection_end)
                      AND selected_count < capacity
                )
                THEN RAISE(ABORT, '课程未开放、非选课时间或名额已满')
            END;

            SELECT CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM course_enrollment ce
                    JOIN course_schedule old_s
                      ON old_s.course_id = ce.course_id
                     AND old_s.status = 'ACTIVE'
                    JOIN course_schedule new_s
                      ON new_s.course_id = NEW.course_id
                     AND new_s.status = 'ACTIVE'
                    WHERE ce.student_id = NEW.student_id
                      AND ce.status = 'SELECTED'
                      AND old_s.semester = new_s.semester
                      AND old_s.week_day = new_s.week_day
                      AND old_s.start_section <= new_s.end_section
                      AND old_s.end_section >= new_s.start_section
                      AND MAX(old_s.start_week, new_s.start_week)
                          <= MIN(old_s.end_week, new_s.end_week)
                      AND (
                          old_s.week_type = 'ALL'
                          OR new_s.week_type = 'ALL'
                          OR (
                              old_s.week_type = new_s.week_type
                              AND (
                                  (old_s.week_type = 'ODD'
                                   AND (
                                       MAX(old_s.start_week, new_s.start_week) % 2 = 1
                                       OR MAX(old_s.start_week, new_s.start_week) + 1
                                          <= MIN(old_s.end_week, new_s.end_week)
                                   ))
                                  OR
                                  (old_s.week_type = 'EVEN'
                                   AND (
                                       MAX(old_s.start_week, new_s.start_week) % 2 = 0
                                       OR MAX(old_s.start_week, new_s.start_week) + 1
                                          <= MIN(old_s.end_week, new_s.end_week)
                                   ))
                              )
                          )
                      )
                )
                THEN RAISE(ABORT, '所选课程与已有课程时间冲突')
            END;
        END;

        CREATE TRIGGER trg_enrollment_update_validate
        BEFORE UPDATE OF status ON course_enrollment
        FOR EACH ROW
        WHEN OLD.status = 'DROPPED' AND NEW.status = 'SELECTED'
        BEGIN
            SELECT CASE
                WHEN NOT EXISTS (
                    SELECT 1 FROM sys_user
                    WHERE id = NEW.student_id
                      AND role = 'STUDENT'
                      AND status = 1
                )
                THEN RAISE(ABORT, '只有正常学生账号可以选课')
            END;

            SELECT CASE
                WHEN NOT EXISTS (
                    SELECT 1 FROM course
                    WHERE id = NEW.course_id
                      AND status = 1
                      AND selection_status = 'OPEN'
                      AND datetime('now') >= datetime(selection_start)
                      AND datetime('now') <= datetime(selection_end)
                      AND selected_count < capacity
                )
                THEN RAISE(ABORT, '课程未开放、非选课时间或名额已满')
            END;

            SELECT CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM course_enrollment ce
                    JOIN course_schedule old_s
                      ON old_s.course_id = ce.course_id
                     AND old_s.status = 'ACTIVE'
                    JOIN course_schedule new_s
                      ON new_s.course_id = NEW.course_id
                     AND new_s.status = 'ACTIVE'
                    WHERE ce.student_id = NEW.student_id
                      AND ce.status = 'SELECTED'
                      AND ce.id <> NEW.id
                      AND old_s.semester = new_s.semester
                      AND old_s.week_day = new_s.week_day
                      AND old_s.start_section <= new_s.end_section
                      AND old_s.end_section >= new_s.start_section
                      AND MAX(old_s.start_week, new_s.start_week)
                          <= MIN(old_s.end_week, new_s.end_week)
                      AND (
                          old_s.week_type = 'ALL'
                          OR new_s.week_type = 'ALL'
                          OR (
                              old_s.week_type = new_s.week_type
                              AND (
                                  (old_s.week_type = 'ODD'
                                   AND (
                                       MAX(old_s.start_week, new_s.start_week) % 2 = 1
                                       OR MAX(old_s.start_week, new_s.start_week) + 1
                                          <= MIN(old_s.end_week, new_s.end_week)
                                   ))
                                  OR
                                  (old_s.week_type = 'EVEN'
                                   AND (
                                       MAX(old_s.start_week, new_s.start_week) % 2 = 0
                                       OR MAX(old_s.start_week, new_s.start_week) + 1
                                          <= MIN(old_s.end_week, new_s.end_week)
                                   ))
                              )
                          )
                      )
                )
                THEN RAISE(ABORT, '所选课程与已有课程时间冲突')
            END;
        END;
        """
    )

    conn.commit()


if __name__ == "__main__":
    connection = connect_db(Config.DATABASE)
    try:
        migrate(connection)
        print(f"数据库迁移完成：{Config.DATABASE}")
    finally:
        connection.close()
