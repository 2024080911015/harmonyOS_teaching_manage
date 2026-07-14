import {
  Student, Teacher, Class, Course, LessonPlan,
  CourseType, Gender, UserRole,
  Attachment, LeaveRequest, LeaveType, LeaveStatus
} from '../models/AppModels';
import {
  User, CourseSchedule, CourseAdjustment,
  AdjustmentStatus, ApprovalType, getApprovalType, UserRole as DataUserRole, CourseStatus, BookingStatus
} from '../models/DataModels';
import { BookingRequest, ClassroomUserRole } from '../models/ClassroomModels';
import { CourseSelectionService } from './CourseSelectionService';

// 模拟数据服务
export class DataService {
  private static instance: DataService;

  // 模拟数据
  private students: Student[] = [];
  private teachers: Teacher[] = [];
  private classes: Class[] = [];
  private courses: Course[] = [];
  private lessonPlans: LessonPlan[] = [];
  
  // 调课功能相关数据
  private currentUser: User | null = null;
  private courseAdjustments: CourseAdjustment[] = [];
  private bookingRequests: BookingRequest[] = [];
  private coursesData: CourseSchedule[] = [];
  
  // 请假功能相关数据
  private leaveRequests: LeaveRequest[] = [];

  private constructor() {
    this.initMockData();
  }

  public static getInstance(): DataService {
    if (!DataService.instance) {
      DataService.instance = new DataService();
    }
    return DataService.instance;
  }

  // 初始化模拟数据
  private initMockData(): void {
    // ---- 生成学生数据 ----
    this.students = [
      { id: '202401001', name: '张三', gender: Gender.MALE, classId: 'class001', className: '计算机科学与技术2024级1班', grade: '2024级', major: '计算机科学与技术', position: '班长', phone: '13800138001', email: 'zhangsan@edu.cn' },
      { id: '202401002', name: '李四', gender: Gender.MALE, classId: 'class001', className: '计算机科学与技术2024级1班', grade: '2024级', major: '计算机科学与技术', position: '学习委员', phone: '13800138002', email: 'lisi@edu.cn' },
      { id: '202401003', name: '王芳', gender: Gender.FEMALE, classId: 'class001', className: '计算机科学与技术2024级1班', grade: '2024级', major: '计算机科学与技术', position: '团支书', phone: '13800138003', email: 'wangfang@edu.cn' },
      { id: '202401004', name: '赵明', gender: Gender.MALE, classId: 'class001', className: '计算机科学与技术2024级1班', grade: '2024级', major: '计算机科学与技术', position: '体育委员', phone: '13800138004' },
      { id: '202401005', name: '孙悦', gender: Gender.FEMALE, classId: 'class001', className: '计算机科学与技术2024级1班', grade: '2024级', major: '计算机科学与技术', position: '文艺委员', phone: '13800138005' },
      { id: '202401006', name: '周阳', gender: Gender.MALE, classId: 'class001', className: '计算机科学与技术2024级1班', grade: '2024级', major: '计算机科学与技术', position: '学生', phone: '13800138006' },
      { id: '202401007', name: '吴婷', gender: Gender.FEMALE, classId: 'class001', className: '计算机科学与技术2024级1班', grade: '2024级', major: '计算机科学与技术', position: '学生', phone: '13800138007' },
      { id: '202401008', name: '郑凯', gender: Gender.MALE, classId: 'class001', className: '计算机科学与技术2024级1班', grade: '2024级', major: '计算机科学与技术', position: '学生', phone: '13800138008' },
      { id: '202402001', name: '陈雪', gender: Gender.FEMALE, classId: 'class002', className: '软件工程2024级1班', grade: '2024级', major: '软件工程', position: '班长', phone: '13800138009', email: 'chenxue@edu.cn' },
      { id: '202402002', name: '林峰', gender: Gender.MALE, classId: 'class002', className: '软件工程2024级1班', grade: '2024级', major: '软件工程', position: '学习委员', phone: '13800138010' },
      { id: '202402003', name: '杨柳', gender: Gender.FEMALE, classId: 'class002', className: '软件工程2024级1班', grade: '2024级', major: '软件工程', position: '学生', phone: '13800138011' },
      { id: '202403001', name: '黄磊', gender: Gender.MALE, classId: 'class003', className: '人工智能2024级1班', grade: '2024级', major: '人工智能', position: '班长', phone: '13800138012' },
      { id: '202403002', name: '刘洋', gender: Gender.FEMALE, classId: 'class003', className: '人工智能2024级1班', grade: '2024级', major: '人工智能', position: '学生', phone: '13800138013' },
    ];

    // ---- 生成教师数据 ----
    this.teachers = [
      { id: 'T001', name: '王教授', department: '计算机科学与技术教研室', title: '教授', phone: '13900139001', email: 'wang@edu.cn', classId: 'class001' },
      { id: 'T002', name: '李副教授', department: '软件工程教研室', title: '副教授', phone: '13900139002', email: 'li@edu.cn', classId: 'class002' },
      { id: 'T003', name: '张讲师', department: '人工智能教研室', title: '讲师', phone: '13900139003', email: 'zhang@edu.cn', classId: 'class003' },
      { id: 'T004', name: '刘教授', department: '计算机科学与技术教研室', title: '教授', phone: '13900139004', email: 'liu@edu.cn' },
    ];

    // ---- 生成班级数据 ----
    this.classes = [
      {
        id: 'class001',
        name: '计算机科学与技术2024级1班',
        grade: '2024级',
        major: '计算机科学与技术',
        department: '计算机学院',
        headTeacher: '王教授',
        monitor: '张三',
        studentCount: 8,
        students: this.students.filter(s => s.classId === 'class001')
      },
      {
        id: 'class002',
        name: '软件工程2024级1班',
        grade: '2024级',
        major: '软件工程',
        department: '计算机学院',
        headTeacher: '李副教授',
        monitor: '陈雪',
        studentCount: 3,
        students: this.students.filter(s => s.classId === 'class002')
      },
      {
        id: 'class003',
        name: '人工智能2024级1班',
        grade: '2024级',
        major: '人工智能',
        department: '计算机学院',
        headTeacher: '张讲师',
        monitor: '黄磊',
        studentCount: 2,
        students: this.students.filter(s => s.classId === 'class003')
      }
    ];

    // ---- 生成课程数据 ----
    this.courses = [
      { id: 'CS101', name: '数据结构与算法', credit: 4, type: CourseType.REQUIRED, department: '计算机科学与技术教研室', teacher: '王教授', syllabus: '/syllabus/cs101.pdf', semester: '2025-2026学年第一学期', grade: '2024级', major: '计算机科学与技术', makeUpExam: true },
      { id: 'CS102', name: '操作系统', credit: 3.5, type: CourseType.REQUIRED, department: '计算机科学与技术教研室', teacher: '刘教授', syllabus: '/syllabus/cs102.pdf', semester: '2025-2026学年第一学期', grade: '2024级', major: '计算机科学与技术', makeUpExam: true },
      { id: 'SE101', name: '软件工程导论', credit: 3, type: CourseType.REQUIRED, department: '软件工程教研室', teacher: '李副教授', syllabus: '/syllabus/se101.pdf', semester: '2025-2026学年第一学期', grade: '2024级', major: '软件工程', makeUpExam: true },
      { id: 'SE102', name: '面向对象程序设计', credit: 4, type: CourseType.REQUIRED, department: '软件工程教研室', teacher: '李副教授', syllabus: '/syllabus/se102.pdf', semester: '2025-2026学年第一学期', grade: '2024级', major: '软件工程', makeUpExam: false },
      { id: 'AI101', name: '机器学习基础', credit: 3.5, type: CourseType.REQUIRED, department: '人工智能教研室', teacher: '张讲师', syllabus: '/syllabus/ai101.pdf', semester: '2025-2026学年第一学期', grade: '2024级', major: '人工智能', makeUpExam: true },
      { id: 'AI102', name: '深度学习', credit: 3, type: CourseType.ELECTIVE, department: '人工智能教研室', teacher: '张讲师', syllabus: '/syllabus/ai102.pdf', semester: '2025-2026学年第一学期', grade: '2024级', major: '人工智能', makeUpExam: false },
      { id: 'PUB101', name: '大学英语', credit: 2, type: CourseType.PUBLIC, department: '基础教研室', teacher: '陈老师', syllabus: '/syllabus/pub101.pdf', semester: '2025-2026学年第一学期', grade: '2024级', major: '全部', makeUpExam: true },
    ];

    // ---- 生成教案数据 ----
    this.lessonPlans = [
      {
        id: 'LP001',
        title: '数据结构 - 第3章 栈与队列',
        classId: 'class001',
        courseId: 'CS101',
        teacherId: 'T001',
        teacherName: '王教授',
        uploadTime: '2026-07-05 14:30',
        content: '本章主要讲解栈和队列的基本概念、实现方式及应用场景...',
        attachments: [
          { id: 'A001', name: '栈与队列PPT.pdf', type: 'file', url: '/files/stack_queue.pdf', size: 2048000 },
          { id: 'A002', name: '演示视频.mp4', type: 'video', url: '/videos/demo.mp4', size: 15000000 },
        ],
        description: '第三章教学课件及视频'
      },
      {
        id: 'LP002',
        title: '操作系统 - 进程管理',
        classId: 'class001',
        courseId: 'CS102',
        teacherId: 'T004',
        teacherName: '刘教授',
        uploadTime: '2026-07-03 10:15',
        content: '进程的概念、状态转换、调度算法...',
        attachments: [
          { id: 'A003', name: '进程管理讲义.pdf', type: 'file', url: '/files/process.pdf', size: 1024000 },
          { id: 'A004', name: '调度算法图解.png', type: 'image', url: '/images/schedule.png', size: 512000 },
        ],
        description: '进程管理章节完整教案'
      },
      {
        id: 'LP003',
        title: '机器学习 - 线性回归',
        classId: 'class003',
        courseId: 'AI101',
        teacherId: 'T003',
        teacherName: '张讲师',
        uploadTime: '2026-07-01 09:00',
        content: '线性回归的原理、损失函数、梯度下降法...',
        attachments: [
          { id: 'A005', name: '线性回归笔记.pdf', type: 'file', url: '/files/linear_regression.pdf', size: 800000 },
        ],
        description: '机器学习基础课程教案'
      },
    ];
    
    // ---- 初始化调课功能数据 ----
    // 初始化当前用户（默认为教务处）
    this.currentUser = {
      id: 'admin001',
      name: '教务管理员',
      role: DataUserRole.ACADEMIC_AFFAIRS,
      department: '教务处'
    };
    
    // 初始化课程数据
    this.coursesData = [
      {
        id: 'CS001',
        courseId: 'C001',
        name: '高等数学',
        teacherId: 'T001',
        teacherName: '王教授',
        department: '数学系',
        college: '理学院',
        hours: 64,
        schedule: '周一 1-2节, 周三 3-4节',
        classroom: '教学楼A101',
        credit: 4,
        courseStatus: CourseStatus.NORMAL,
        weekRange: { startWeek: 1, endWeek: 16 }
      },
      {
        id: 'CS002',
        courseId: 'C002',
        name: '数据结构',
        teacherId: 'T002',
        teacherName: '李教授',
        department: '计算机系',
        college: '信息学院',
        hours: 48,
        schedule: '周二 1-2节, 周四 5-6节',
        classroom: '教学楼B203',
        credit: 3,
        courseStatus: CourseStatus.NORMAL,
        weekRange: { startWeek: 1, endWeek: 16 }
      },
      {
        id: 'CS003',
        courseId: 'C003',
        name: '操作系统',
        teacherId: 'T001',
        teacherName: '王教授',
        department: '计算机系',
        college: '信息学院',
        hours: 56,
        schedule: '周五 3-4节',
        classroom: '教学楼C301',
        credit: 3.5,
        courseStatus: CourseStatus.NORMAL,
        weekRange: { startWeek: 1, endWeek: 16 }
      }
    ];
    
    // 初始化调课申请数据
    this.courseAdjustments = [
      {
        id: 'ADJ001',
        courseId: 'C001',
        courseName: '高等数学',
        teacherId: 'T001',
        teacherName: '王教授',
        department: '数学系',
        college: '理学院',
        originalSchedule: '周一 1-2节, 周三 3-4节',
        newSchedule: '周一 3-4节, 周三 5-6节',
        originalClassroom: '教学楼A101',
        newClassroom: '教学楼A102',
        hours: 10,
        reason: '教室设备故障，需要更换教室',
        status: AdjustmentStatus.PENDING_ACADEMIC,
        approvalType: ApprovalType.ACADEMIC_AFFAIRS,
        createTime: '2026-07-08 10:00',
        updateTime: '2026-07-08 10:00'
      },
      {
        id: 'ADJ002',
        courseId: 'C002',
        courseName: '数据结构',
        teacherId: 'T002',
        teacherName: '李教授',
        department: '计算机系',
        college: '信息学院',
        originalSchedule: '周二 1-2节, 周四 5-6节',
        newSchedule: '周二 3-4节, 周四 7-8节',
        originalClassroom: '教学楼B203',
        newClassroom: '教学楼B204',
        hours: 6,
        reason: '与其他课程时间冲突',
        status: AdjustmentStatus.AUTO_APPROVED,
        approvalType: ApprovalType.AUTO,
        createTime: '2026-07-09 14:00',
        updateTime: '2026-07-09 14:00'
      }
    ];
  }

  // ----- 获取数据方法 -----

  getAllStudents(): Student[] {
    return [...this.students];
  }

  getStudentsByClass(classId: string): Student[] {
    return this.students.filter(s => s.classId === classId);
  }

  getStudentById(id: string): Student | undefined {
    return this.students.find(s => s.id === id);
  }

  getAllTeachers(): Teacher[] {
    return [...this.teachers];
  }

  getTeacherById(id: string): Teacher | undefined {
    return this.teachers.find(t => t.id === id);
  }

  getTeacherByClassId(classId: string): Teacher | undefined {
    return this.teachers.find(t => t.classId === classId);
  }

  getAllClasses(): Class[] {
    return [...this.classes];
  }

  getClassById(id: string): Class | undefined {
    return this.classes.find(c => c.id === id);
  }

  getClassByName(name: string): Class | undefined {
    return this.classes.find(c => c.name === name);
  }

  getAllCourses(): Course[] {
    return [...this.courses];
  }

  getCoursesBySemester(semester: string): Course[] {
    return this.courses.filter(c => c.semester === semester);
  }

  getCoursesByDepartment(department: string): Course[] {
    return this.courses.filter(c => c.department === department);
  }

  getAllLessonPlans(): LessonPlan[] {
    return [...this.lessonPlans];
  }

  getLessonPlansByClass(classId: string): LessonPlan[] {
    return this.lessonPlans.filter(lp => lp.classId === classId);
  }

  getLessonPlansByTeacher(teacherId: string): LessonPlan[] {
    return this.lessonPlans.filter(lp => lp.teacherId === teacherId);
  }

  // ----- 搜索方法 -----

  searchStudents(keyword: string): Student[] {
    const lowerKeyword = keyword.toLowerCase();
    return this.students.filter(s =>
    s.id.includes(keyword) ||
      s.name.includes(keyword) ||
      s.className.includes(keyword) ||
      s.major.includes(keyword) ||
      s.position.includes(keyword)
    );
  }

  searchCourses(keyword: string): Course[] {
    const lowerKeyword = keyword.toLowerCase();
    return this.courses.filter(c =>
    c.id.toLowerCase().includes(lowerKeyword) ||
      c.name.includes(keyword) ||
      c.department.includes(keyword) ||
      c.teacher.includes(keyword)
    );
  }

  // ----- 模拟添加/更新方法 (用于演示) -----

  addLessonPlan(plan: LessonPlan): void {
    this.lessonPlans.push(plan);
  }
  
  // 更新教案
  updateLessonPlan(plan: LessonPlan): void {
    const index = this.lessonPlans.findIndex(p => p.id === plan.id);
    if (index !== -1) {
      this.lessonPlans[index] = plan;
    }
  }
  
  // 删除教案
  deleteLessonPlan(planId: string): void {
    this.lessonPlans = this.lessonPlans.filter(p => p.id !== planId);
  }
  
  // ----- 调课功能相关方法 -----
  
  // 获取当前用户
  getCurrentUser(): User | null {
    return this.currentUser;
  }
  
  // 设置当前用户（登录时调用）
  setCurrentUser(user: User): void {
    this.currentUser = user;
  }
  
  // 获取教师的课程列表
  getTeacherCourses(userId: string): CourseSchedule[] {
    return this.coursesData.filter(course => course.teacherId === userId);
  }
  
  // 获取教师的调课申请列表
  getTeacherAdjustments(userId: string): CourseAdjustment[] {
    return this.courseAdjustments.filter(adj => adj.teacherId === userId);
  }
  
  // 获取学生选修的课程列表
  getStudentCourses(studentId: string): CourseSchedule[] {
    // 从选课服务获取学生已选课程
    const selectionService = CourseSelectionService.getInstance();
    const selectedRecords = selectionService.getStudentSelectedCourses(studentId);
    
    // 转换为CourseSchedule格式
    const courses: CourseSchedule[] = [];
    
    for (const record of selectedRecords) {
      // 获取课程详细信息
      const selectableCourses = selectionService.getSelectableCourses();
      const selectableCourse = selectableCourses.find(c => c.id === record.courseId);
      
      if (selectableCourse) {
        // 转换为CourseSchedule格式
        const courseSchedule: CourseSchedule = {
          id: `schedule-${selectableCourse.id}`,
          courseId: selectableCourse.id,
          name: selectableCourse.name,
          teacherId: selectableCourse.teacherId,
          teacherName: selectableCourse.teacherName,
          department: '计算机系', // 默认值
          college: '信息学院', // 默认值
          hours: selectableCourse.credit * 16, // 学时 = 学分 * 16
          schedule: selectableCourse.schedule,
          classroom: selectableCourse.classroom,
          credit: selectableCourse.credit,
          description: selectableCourse.description || '',
          courseStatus: CourseStatus.NORMAL
        };
        courses.push(courseSchedule);
      }
    }
    
    return courses;
  }
  
  // 获取教务处待审批的调课申请
  getAcademicAffairsPending(): CourseAdjustment[] {
    return this.courseAdjustments.filter(
      adj => adj.status === AdjustmentStatus.PENDING_ACADEMIC
    );
  }
  
  // 获取学院领导待审批的调课申请
  getCollegeLeaderPending(college: string): CourseAdjustment[] {
    return this.courseAdjustments.filter(
      adj => adj.status === AdjustmentStatus.PENDING_COLLEGE &&
             adj.college === college
    );
  }
  
  // 提交调课申请
  submitAdjustment(
    courseId: string,
    courseName: string,
    teacherId: string,
    teacherName: string,
    department: string,
    college: string,
    originalSchedule: string,
    newSchedule: string,
    originalClassroom: string,
    newClassroom: string,
    hours: number,
    reason: string
  ): void {
    const approvalType = getApprovalType(hours);
    const status = approvalType === ApprovalType.AUTO ? 
                   AdjustmentStatus.AUTO_APPROVED : 
                   AdjustmentStatus.PENDING_ACADEMIC;
    
    const adjustment: CourseAdjustment = {
      id: `ADJ${Date.now()}`,
      courseId,
      courseName,
      teacherId,
      teacherName,
      department,
      college,
      originalSchedule,
      newSchedule,
      originalClassroom,
      newClassroom,
      hours,
      reason,
      status,
      approvalType,
      createTime: new Date().toLocaleString(),
      updateTime: new Date().toLocaleString()
    };
    
    this.courseAdjustments.push(adjustment);
  }
  
  // 教务处审批调课申请
  approveByAcademicAffairs(id: string, approverId: string, approverName: string, 
                           isApprove: boolean, comment: string): void {
    const adjustment = this.courseAdjustments.find(adj => adj.id === id);
    if (!adjustment) return;
    
    adjustment.academicAffairsApproval = {
      approverId,
      approverName,
      approvalTime: new Date().toLocaleString(),
      approvalComment: comment,
      isApproved: isApprove
    };
    
    if (!isApprove) {
      adjustment.status = AdjustmentStatus.REJECTED;
    } else if (adjustment.approvalType === ApprovalType.COLLEGE_LEADER) {
      // 需要学院领导审批
      adjustment.status = AdjustmentStatus.PENDING_COLLEGE;
    } else {
      // 不需要学院领导审批，直接通过
      adjustment.status = AdjustmentStatus.APPROVED;
    }
    
    adjustment.updateTime = new Date().toLocaleString();
  }
  
  // 学院领导审批调课申请
  approveByCollegeLeader(id: string, approverId: string, approverName: string,
                         isApprove: boolean, comment: string): void {
    const adjustment = this.courseAdjustments.find(adj => adj.id === id);
    if (!adjustment) return;
    
    adjustment.collegeLeaderApproval = {
      approverId,
      approverName,
      approvalTime: new Date().toLocaleString(),
      approvalComment: comment,
      isApproved: isApprove
    };
    
    adjustment.status = isApprove ? AdjustmentStatus.APPROVED : AdjustmentStatus.REJECTED;
    adjustment.updateTime = new Date().toLocaleString();
  }
  
  // 获取教务处待审批列表
  getAcademicAffairsPendingAdjustments(): CourseAdjustment[] {
    return this.courseAdjustments.filter(adj => 
      adj.status === AdjustmentStatus.PENDING_ACADEMIC
    );
  }
  
  // 获取学院领导待审批列表
  getCollegeLeaderPendingAdjustments(): CourseAdjustment[] {
    return this.courseAdjustments.filter(adj => 
      adj.status === AdjustmentStatus.PENDING_COLLEGE
    );
  }
  
  // ========== 教室预约审批 ==========
  
  // 获取教务处待审批的教室预约
  getAcademicAffairsPendingBookings(): BookingRequest[] {
    return this.bookingRequests.filter(booking => 
      booking.status === BookingStatus.PENDING_ACADEMIC ||
      booking.status === BookingStatus.PENDING_CANCEL
    );
  }
  
  // 获取学院领导待审批的教室预约
  getCollegeLeaderPendingBookings(): BookingRequest[] {
    return this.bookingRequests.filter(booking => 
      booking.status === BookingStatus.PENDING_COLLEGE
    );
  }
  
  // 教务处审批教室预约
  approveBookingByAcademicAffairs(
    bookingId: string,
    approve: boolean,
    approverId: string,
    approverName: string
  ): boolean {
    const booking = this.bookingRequests.find(b => b.id === bookingId);
    if (!booking) {
      return false;
    }
    
    if (approve) {
      // 通过审批
      booking.status = BookingStatus.APPROVED;
      booking.academicApproverId = approverId;
      booking.academicApproverName = approverName;
      booking.academicApproveTime = new Date().toLocaleString();
      
      // 同步教室占用状态
      this.syncBookingToClassroom(booking);
    } else {
      // 拒绝
      booking.status = BookingStatus.REJECTED;
      booking.academicApproverId = approverId;
      booking.academicApproverName = approverName;
      booking.academicApproveTime = new Date().toLocaleString();
    }
    
    booking.updateTime = new Date().toLocaleString();
    return true;
  }
  
  // 同步教室预约到教室状态
  private syncBookingToClassroom(booking: BookingRequest): void {
    // 这里可以更新教室的占用状态
    // 由于ClassroomStatusPage使用的是本地数据，这里暂时只更新booking的状态
    // 实际应用中应该更新教室的时间段状态
    console.info(`教室预约已通过：${booking.classroomName} - ${booking.date} - ${booking.timeSlot}`);
  }
  
  // 学院领导审批教室预约
  approveBookingByCollegeLeader(
    bookingId: string,
    approve: boolean,
    approverId: string,
    approverName: string
  ): boolean {
    const booking = this.bookingRequests.find(b => b.id === bookingId);
    if (!booking) {
      return false;
    }
    
    if (approve) {
      // 通过审批，转交教务处
      booking.status = BookingStatus.PENDING_ACADEMIC;
      booking.collegeApproverId = approverId;
      booking.collegeApproverName = approverName;
      booking.collegeApproveTime = new Date().toLocaleString();
    } else {
      // 拒绝
      booking.status = BookingStatus.REJECTED;
      booking.collegeApproverId = approverId;
      booking.collegeApproverName = approverName;
      booking.collegeApproveTime = new Date().toLocaleString();
    }
    
    booking.updateTime = new Date().toLocaleString();
    return true;
  }
  
  // ========== 取消调课申请 ==========
  
  // 取消调课申请（未审核或审核中可直接取消）
  cancelAdjustment(adjustmentId: string): boolean {
    const adjustment = this.courseAdjustments.find(adj => adj.id === adjustmentId);
    if (!adjustment) {
      return false;
    }
    
    // 只有待审核状态才能直接取消
    if (adjustment.status === AdjustmentStatus.PENDING_ACADEMIC || 
        adjustment.status === AdjustmentStatus.PENDING_COLLEGE) {
      adjustment.status = AdjustmentStatus.CANCELLED;
      adjustment.updateTime = new Date().toLocaleString();
      return true;
    }
    
    return false;
  }
  
  // 申请取消已审核通过的调课（需要教务处审批）
  requestCancelAdjustment(adjustmentId: string): boolean {
    const adjustment = this.courseAdjustments.find(adj => adj.id === adjustmentId);
    if (!adjustment) {
      return false;
    }
    
    // 只有已审核通过的状态才能申请取消
    if (adjustment.status === AdjustmentStatus.APPROVED || 
        adjustment.status === AdjustmentStatus.AUTO_APPROVED) {
      adjustment.status = AdjustmentStatus.PENDING_CANCEL;
      adjustment.updateTime = new Date().toLocaleString();
      return true;
    }
    
    return false;
  }
  
  // 教务处审批取消申请
  approveCancelByAcademicAffairs(
    adjustmentId: string,
    approverId: string,
    approverName: string,
    isApprove: boolean,
    comment?: string
  ): boolean {
    const adjustment = this.courseAdjustments.find(adj => adj.id === adjustmentId);
    if (!adjustment || adjustment.status !== AdjustmentStatus.PENDING_CANCEL) {
      return false;
    }
    
    adjustment.cancelApproval = {
      approverId,
      approverName,
      approvalTime: new Date().toLocaleString(),
      approvalComment: comment,
      isApproved: isApprove
    };
    
    if (isApprove) {
      adjustment.status = AdjustmentStatus.CANCELLED;
    } else {
      // 如果取消申请被拒绝，恢复为已审核通过状态
      adjustment.status = AdjustmentStatus.APPROVED;
    }
    
    adjustment.updateTime = new Date().toLocaleString();
    return true;
  }
  
  // 获取待取消审批列表（教务处）
  getPendingCancelAdjustments(): CourseAdjustment[] {
    return this.courseAdjustments.filter(adj => 
      adj.status === AdjustmentStatus.PENDING_CANCEL
    );
  }
  
  // 旧方法保留兼容性
  approveAdjustment(id: string, isApprove: boolean, comment: string): void {
    const adjustment = this.courseAdjustments.find(adj => adj.id === id);
    if (adjustment) {
      adjustment.status = isApprove ? AdjustmentStatus.APPROVED : AdjustmentStatus.REJECTED;
      adjustment.updateTime = new Date().toLocaleString();
      
      // 如果审批通过，更新课程的排课信息
      if (isApprove) {
        this.syncCourseAdjustment(adjustment);
      }
    }
  }
  
  // 同步课程调课信息到课程表
  private syncCourseAdjustment(adjustment: CourseAdjustment): void {
    const course = this.coursesData.find(c => c.id === adjustment.courseId);
    if (course) {
      // 更新课程的排课信息
      if (adjustment.newSchedule) {
        course.schedule = adjustment.newSchedule;
      }
      if (adjustment.newClassroom) {
        course.classroom = adjustment.newClassroom;
      }
      // 更新课程状态为已调课
      course.courseStatus = CourseStatus.ADJUSTED;
      
      // 如果有新的周数范围，更新周数
      if (adjustment.newWeekRange) {
        course.weekRange = adjustment.newWeekRange;
      }
    }
  }
  
  // ========== 教室预约申请管理 ==========
  
  // 提交教室预约申请
  submitBookingRequest(
    classroomId: string,
    classroomName: string,
    date: string,
    startTime: string,
    endTime: string,
    purpose: string,
    applicantId: string,
    applicantName: string,
    applicantRole: string
  ): BookingRequest {
    const request: BookingRequest = {
      id: `BK${Date.now()}`,
      classroomId,
      classroomName,
      date,
      startTime,
      endTime,
      timeSlot: `${startTime}-${endTime}`,
      purpose,
      applicantId,
      applicant: applicantName,
      applicantRole: applicantRole as ClassroomUserRole,
      status: BookingStatus.PENDING_ACADEMIC,
      createTime: new Date().toLocaleString(),
      updateTime: new Date().toLocaleString()
    };
    this.bookingRequests.push(request);
    return request;
  }
  
  // 修改预约申请
  updateBookingRequest(id: string, date: string, startTime: string, endTime: string, purpose: string): boolean {
    const request = this.bookingRequests.find(req => req.id === id);
    if (!request || request.status !== BookingStatus.PENDING_ACADEMIC) return false;
    
    request.date = date;
    request.startTime = startTime;
    request.endTime = endTime;
    request.purpose = purpose;
    request.updateTime = new Date().toLocaleString();
    return true;
  }
  
  // 审批预约申请
  approveBookingRequest(id: string, isApprove: boolean): boolean {
    const request = this.bookingRequests.find(req => req.id === id);
    if (!request || request.status !== BookingStatus.PENDING_ACADEMIC) return false;
    
    request.status = isApprove ? BookingStatus.APPROVED : BookingStatus.REJECTED;
    request.updateTime = new Date().toLocaleString();
    return true;
  }
  
  // 获取所有待审批的预约申请
  getPendingBookingRequests(): BookingRequest[] {
    return this.bookingRequests.filter(req => req.status === BookingStatus.PENDING_ACADEMIC);
  }
  
  // ========== 取消教室预约申请 ==========
  
  // 取消预约申请（未审核可直接取消）
  cancelBookingRequest(requestId: string): boolean {
    const request = this.bookingRequests.find(req => req.id === requestId);
    if (!request) {
      return false;
    }
    
    // 只有待审核状态才能直接取消
    if (request.status === BookingStatus.PENDING_ACADEMIC) {
      request.status = BookingStatus.CANCELLED;
      request.updateTime = new Date().toLocaleString();
      return true;
    }
    
    return false;
  }
  
  // 申请取消已审核通过的预约（需要教务处审批）
  requestCancelBooking(requestId: string): boolean {
    const request = this.bookingRequests.find(req => req.id === requestId);
    if (!request) {
      return false;
    }
    
    // 只有已审核通过的状态才能申请取消
    if (request.status === BookingStatus.APPROVED) {
      request.status = BookingStatus.PENDING_CANCEL;
      request.updateTime = new Date().toLocaleString();
      return true;
    }
    
    return false;
  }
  
  // 教务处审批取消预约申请
  approveCancelBooking(
    requestId: string,
    approverId: string,
    approverName: string,
    isApprove: boolean,
    comment?: string
  ): boolean {
    const request = this.bookingRequests.find(req => req.id === requestId);
    if (!request || request.status !== BookingStatus.PENDING_CANCEL) {
      return false;
    }
    
    request.cancelApproval = {
      approverId,
      approverName,
      approvalTime: new Date().toLocaleString(),
      approvalComment: comment,
      isApproved: isApprove
    };
    
    if (isApprove) {
      request.status = BookingStatus.CANCELLED;
    } else {
      // 如果取消申请被拒绝，恢复为已审核通过状态
      request.status = BookingStatus.APPROVED;
    }
    
    request.updateTime = new Date().toLocaleString();
    return true;
  }
  
  // 获取待取消审批的预约列表（教务处）
  getPendingCancelBookings(): BookingRequest[] {
    return this.bookingRequests.filter(req => 
      req.status === BookingStatus.PENDING_CANCEL
    );
  }
  
  // 获取用户的预约申请列表
  getUserBookingRequests(applicantId: string): BookingRequest[] {
    return this.bookingRequests.filter(req => req.applicantId === applicantId);
  }
  
  // ========== 请假管理功能 ==========
  
  // 创建请假申请
  createLeaveRequest(
    studentId: string,
    studentName: string,
    className: string,
    leaveType: LeaveType,
    reason: string,
    startTime: string,
    endTime: string,
    attachments: Attachment[]
  ): LeaveRequest | null {
    // 检查是否有未完成的请假
    const existingLeave = this.leaveRequests.find(
      leave => leave.studentId === studentId && 
      leave.status !== LeaveStatus.CANCELLED &&
      leave.status !== LeaveStatus.REJECTED &&
      leave.status !== LeaveStatus.WITHDRAWN
    );
    
    if (existingLeave) {
      return null; // 已有未完成的请假，不能申请新的
    }
    
    const newLeave: LeaveRequest = {
      id: `LEAVE_${Date.now()}`,
      studentId,
      studentName,
      className,
      leaveType,
      reason,
      startTime,
      endTime,
      status: LeaveStatus.PENDING,
      attachments,
      createTime: new Date().toLocaleString(),
      isExtended: false
    };
    
    this.leaveRequests.push(newLeave);
    return newLeave;
  }
  
  // 获取学生的请假列表
  getStudentLeaveRequests(studentId: string): LeaveRequest[] {
    return this.leaveRequests.filter(leave => leave.studentId === studentId);
  }
  
  // 获取所有待审批的请假申请（教师端）
  getPendingLeaveRequests(): LeaveRequest[] {
    return this.leaveRequests.filter(leave => leave.status === LeaveStatus.PENDING);
  }
  
  // 获取所有请假申请（教师端）
  getAllLeaveRequests(): LeaveRequest[] {
    return this.leaveRequests;
  }
  
  // 撤回请假申请（学生端）
  withdrawLeaveRequest(leaveId: string): boolean {
    const leave = this.leaveRequests.find(l => l.id === leaveId);
    if (!leave || leave.status !== LeaveStatus.PENDING) {
      return false;
    }
    
    leave.status = LeaveStatus.WITHDRAWN;
    return true;
  }
  
  // 审批请假申请（教师端）
  approveLeaveRequest(
    leaveId: string,
    isApprove: boolean,
    approverId: string,
    approverName: string,
    rejectReason?: string
  ): boolean {
    const leave = this.leaveRequests.find(l => l.id === leaveId);
    if (!leave || leave.status !== LeaveStatus.PENDING) {
      return false;
    }
    
    if (isApprove) {
      leave.status = LeaveStatus.APPROVED;
    } else {
      if (!rejectReason) {
        return false; // 驳回必须填写原因
      }
      leave.status = LeaveStatus.REJECTED;
      leave.rejectReason = rejectReason;
    }
    
    leave.approvalTime = new Date().toLocaleString();
    leave.approverId = approverId;
    leave.approverName = approverName;
    
    return true;
  }
  
  // 上传病历销假（病假专用）
  uploadMedicalRecord(leaveId: string, medicalRecord: Attachment): boolean {
    const leave = this.leaveRequests.find(l => l.id === leaveId);
    if (!leave || 
        leave.leaveType !== LeaveType.SICK || 
        leave.status !== LeaveStatus.APPROVED) {
      return false;
    }
    
    // 检查是否在假期时间内
    const now = new Date();
    const endTime = new Date(leave.endTime);
    if (now > endTime) {
      return false; // 已过假期结束时间
    }
    
    leave.medicalRecord = medicalRecord;
    return true;
  }
  
  // 申请延长假期（病假专用，只能延长一次）
  extendLeaveRequest(leaveId: string, newEndTime: string): boolean {
    const leave = this.leaveRequests.find(l => l.id === leaveId);
    if (!leave || 
        leave.leaveType !== LeaveType.SICK || 
        leave.status !== LeaveStatus.APPROVED ||
        leave.isExtended ||
        !leave.medicalRecord) {
      return false;
    }
    
    // 检查新结束时间是否合理
    const now = new Date();
    const newEnd = new Date(newEndTime);
    const currentEnd = new Date(leave.endTime);
    
    if (newEnd <= currentEnd || newEnd <= now) {
      return false;
    }
    
    leave.originalEndTime = leave.endTime;
    leave.endTime = newEndTime;
    leave.isExtended = true;
    leave.status = LeaveStatus.EXTENDED;
    
    return true;
  }
  
  // 销假（学生端）
  cancelLeaveRequest(leaveId: string): boolean {
    const leave = this.leaveRequests.find(l => l.id === leaveId);
    if (!leave) {
      return false;
    }
    
    // 病假：需要已上传病历
    if (leave.leaveType === LeaveType.SICK) {
      if (!leave.medicalRecord) {
        return false;
      }
    }
    
    // 事假：需要假期已结束
    if (leave.leaveType === LeaveType.PERSONAL) {
      const now = new Date();
      const endTime = new Date(leave.endTime);
      if (now < endTime) {
        return false;
      }
    }
    
    // 检查状态是否为已通过或已延长
    if (leave.status !== LeaveStatus.APPROVED && 
        leave.status !== LeaveStatus.EXTENDED) {
      return false;
    }
    
    leave.status = LeaveStatus.CANCELLED;
    return true;
  }
  
  // 检查学生是否有未完成的请假
  hasActiveLeaveRequest(studentId: string): boolean {
    return this.leaveRequests.some(
      leave => leave.studentId === studentId && 
      leave.status !== LeaveStatus.CANCELLED &&
      leave.status !== LeaveStatus.REJECTED &&
      leave.status !== LeaveStatus.WITHDRAWN
    );
  }
  
  // 登出
  logout(): void {
    this.currentUser = null;
  }
}