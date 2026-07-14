// 选课状态枚举
export enum SelectionStatus {
  NOT_STARTED = '未开始',      // 选课未开始
  IN_PROGRESS = '进行中',      // 选课进行中
  ENDED = '已结束',           // 选课已结束
  FULL = '已满',              // 课程已满
  SELECTED = '已选',          // 已选该课程
  AVAILABLE = '可选'          // 可以选择
}

// 选课时间配置
export interface SelectionPeriod {
  id: string;                  // 选课时段ID
  name: string;                // 选课名称，如 "2024春季学期选课"
  semester: string;            // 学期，如 "2024春季"
  startTime: number;           // 开始时间戳
  endTime: number;             // 结束时间戳
  gradeRange: string[];        // 适用年级，如 ["2022级", "2023级"]
  isActive: boolean;           // 是否激活
}

// 可选课程信息（扩展基础Course模型）
export interface SelectableCourse {
  id: string;                  // 课程ID
  name: string;                // 课程名称
  code: string;                // 课程代码
  teacherId: string;           // 教师ID
  teacherName: string;         // 教师姓名
  type: string;                // 课程类型（必修/选修/公共基础）
  credit: number;              // 学分
  capacity: number;            // 课程容量（最大人数）
  selectedCount: number;       // 已选人数
  classroom: string;           // 教室
  schedule: string;            // 上课时间，如 "周一 3-4节"
  semester: string;            // 学期
  description?: string;        // 课程描述
  prerequisites?: string[];    // 先修课程
}

// 选课记录
export interface CourseSelectionRecord {
  id: string;                  // 选课记录ID
  studentId: string;           // 学号
  courseId: string;            // 课程ID
  selectionTime: number;       // 选课时间戳
  status: SelectionStatus;     // 选课状态
  semester: string;            // 学期
}

// 选课验证结果
export interface SelectionValidation {
  isValid: boolean;            // 是否有效
  status: SelectionStatus;     // 状态
  message: string;             // 提示消息
  canSelect: boolean;          // 是否可以选课
}

// 选课统计信息
export interface SelectionStats {
  totalCourses: number;        // 总课程数
  selectedCourses: number;     // 已选课程数
  requiredCourses: number;     // 必修课数量
  electiveCourses: number;     // 选修课数量
  totalCredits: number;        // 总学分
}
