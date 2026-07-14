// 从DataModels导入用户角色和用户类型
import { UserRole, User } from './DataModels';
// 重新导出以供其他模块使用
export { UserRole, User };

// 性别枚举
export enum Gender {
  MALE = '男',
  FEMALE = '女'
}

// 课程类型枚举
export enum CourseType {
  REQUIRED = '必修',
  ELECTIVE = '选修',
  PUBLIC = '公共基础'
}

// ========== 学生模型 ==========
export interface Student {
  id: string;              // 学号
  name: string;            // 姓名
  gender: Gender;          // 性别
  classId: string;         // 班级ID
  className: string;       // 班级名称
  grade: string;           // 年级，如 "2024级"
  major: string;           // 专业
  position: string;        // 职务，如 "班长"、"学习委员" 等
  phone?: string;          // 电话
  email?: string;          // 邮箱
  avatar?: string;         // 头像URL
}

// ========== 教师模型 ==========
export interface Teacher {
  id: string;              // 教师工号
  name: string;            // 姓名
  department: string;      // 所属院系/教研室
  title: string;           // 职称
  phone?: string;
  email?: string;
  classId?: string;        // 所带班级ID（班主任）
}

// ========== 班级模型 ==========
export interface Class {
  id: string;              // 班级ID
  name: string;            // 班级名称，如 "计算机科学与技术2024级1班"
  grade: string;           // 年级
  major: string;           // 专业
  department: string;      // 所属院系
  headTeacher: string;     // 辅导员/班主任
  monitor: string;         // 班长
  studentCount: number;    // 学生人数
  students: Student[];     // 班级学生列表
}

// ========== 课程模型 ==========
export interface Course {
  id: string;              // 课程代码
  name: string;            // 课程名称
  credit: number;          // 学分
  type: CourseType;        // 课程类型
  department: string;      // 所属教研室
  teacher: string;         // 课程负责人
  syllabus: string;        // 课程标准/大纲URL
  semester: string;        // 学期，如 "2025-2026学年第一学期"
  grade: string;           // 适用年级
  major: string;           // 适用专业
  makeUpExam: boolean;     // 是否参与补考
}

// ========== 教案模型 ==========
export interface LessonPlan {
  id: string;
  title: string;           // 教案标题
  classId: string;         // 所属班级ID
  courseId: string;        // 关联课程ID
  teacherId: string;       // 上传教师ID
  teacherName: string;     // 教师姓名
  uploadTime: string;      // 上传时间
  content: string;         // 文字内容
  attachments: Attachment[]; // 附件（图片、视频等）
  description?: string;
}

// ========== 附件模型 ==========
export interface Attachment {
  id: string;
  name: string;            // 文件名
  type: 'image' | 'video' | 'file';
  url: string;             // 文件URL
  size: number;            // 文件大小（字节）
  uploadTime?: string;     // 上传时间
}

// ========== 请假类型枚举 ==========
export enum LeaveType {
  SICK = '病假',
  PERSONAL = '事假'
}

// ========== 请假状态枚举 ==========
export enum LeaveStatus {
  PENDING = '待审批',      // 待审批
  APPROVED = '已通过',     // 已通过
  REJECTED = '已驳回',     // 已驳回
  WITHDRAWN = '已撤回',    // 已撤回
  CANCELLED = '已销假',    // 已销假
  EXTENDED = '已延长'      // 已延长（病假专用）
}

// ========== 请假申请模型 ==========
export interface LeaveRequest {
  id: string;                    // 请假ID
  studentId: string;             // 学生ID
  studentName: string;           // 学生姓名
  className: string;             // 班级名称
  leaveType: LeaveType;          // 请假类型
  reason: string;                // 请假原因
  startTime: string;             // 开始时间
  endTime: string;               // 结束时间
  status: LeaveStatus;           // 请假状态
  attachments: Attachment[];     // 附件
  medicalRecord?: Attachment;    // 病历附件（病假专用）
  rejectReason?: string;         // 驳回原因
  approvalTime?: string;         // 审批时间
  approverId?: string;           // 审批人ID
  approverName?: string;         // 审批人姓名
  createTime: string;            // 创建时间
  isExtended?: boolean;          // 是否已延长（病假专用）
  originalEndTime?: string;      // 原结束时间（延长前）
}

// ========== 应用状态 ==========
export interface AppState {
  currentUser: Teacher | Student | User | null;
  role: UserRole | null;
  isLoggedIn: boolean;
}
