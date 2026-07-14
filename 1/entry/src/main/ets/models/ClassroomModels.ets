import { BookingStatus } from './DataModels'

// 教室属性类型枚举
export enum RoomType {
  LECTURE_HALL = '梯形教室',
  MULTI_FUNCTION = '多功能教室',
  COMPUTER_ROOM = '机房',
  ORDINARY = '普通教室',
  LABORATORY = '实验室'
}

// 校区枚举
export enum CampusType {
  MAIN = '主校区',
  EAST = '东校区',
  WEST = '西校区',
  SOUTH = '南校区'
}

// 时间段状态
export enum TimeSlotStatus {
  AVAILABLE = '空闲',
  OCCUPIED = '已占用',
  LOCKED = '已锁定',
  BOOKED = '已预约',
  COURSE = '有课程',      // 有课程占用
  PENDING_APPROVAL = '待审核'  // 待审核
}

// 教室模块用户角色（扩展角色）
export enum ClassroomUserRole {
  TEACHER = '教师',
  STUDENT = '学生',
  EXAM_STAFF = '考务人员',
  ADMIN = '管理员'
}

// 时间段接口
export interface TimeSlot {
  id: string
  date: string // YYYY-MM-DD
  startTime: string // HH:mm
  endTime: string // HH:mm
  status: TimeSlotStatus
  occupant?: string // 占用人/锁定人
  purpose?: string // 用途
  isExam?: boolean // 是否为考试锁定
  courseId?: string // 关联的课程ID（如果有课程）
  bookingId?: string // 关联的预约ID（如果是预约）
}

// 教室接口
export interface RoomInfo {
  id: string
  roomNumber: string // 教室编号
  campus: CampusType // 所属校区
  capacity: number // 最大容纳人数
  type: RoomType // 教室属性
  building: string // 所属楼栋
  floor: number // 楼层
  hasProjector: boolean // 是否有投影仪
  hasComputer: boolean // 是否有电脑
  timeSlots: TimeSlot[] // 占用情况
}

// 预约请求接口
export interface BookingRequest {
  id: string                    // 申请ID
  classroomId: string
  classroomName: string         // 教室名称
  date: string
  startTime: string
  endTime: string
  timeSlot: string              // 时间段描述（如"第1-2节"）
  purpose: string
  applicantId: string           // 申请人ID
  applicant: string             // 申请人姓名
  applicantRole: ClassroomUserRole
  status: BookingStatus         // 使用BookingStatus枚举
  createTime: string            // 申请时间
  updateTime: string            // 更新时间
  // 审批信息
  approvalInfo?: ApprovalInfo
  // 取消审批信息（已审核通过的申请需要教务处审批才能取消）
  cancelApproval?: ApprovalInfo
  // 是否需要学院领导审批（根据占用时长判断）
  needCollegeApproval?: boolean
  // 学院领导审批信息
  collegeApproval?: ApprovalInfo
  collegeApproverId?: string
  collegeApproverName?: string
  collegeApproveTime?: string
  // 教务处审批信息
  academicApproverId?: string
  academicApproverName?: string
  academicApproveTime?: string
}

// 审批信息
export interface ApprovalInfo {
  approverId: string
  approverName: string
  approvalTime: string
  approvalComment?: string
  isApproved: boolean
}

// 锁定请求接口
export interface LockRequest {
  classroomId: string
  date: string
  startTime: string
  endTime: string
  examName: string
  locker: string
}
