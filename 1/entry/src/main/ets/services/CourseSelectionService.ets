import { 
  SelectionStatus, 
  SelectionPeriod, 
  SelectableCourse, 
  CourseSelectionRecord,
  SelectionValidation,
  SelectionStats
} from '../models/CourseSelection';

// 时间段接口
interface TimeSlot {
  day: string;
  sections: string[];
}

// 时间冲突结果接口
interface TimeConflictResult {
  hasConflict: boolean;
  message: string;
}

// 选课服务 - 单例模式
export class CourseSelectionService {
  private static instance: CourseSelectionService;
  
  // 选课时段配置
  private selectionPeriods: SelectionPeriod[] = [];
  // 可选课程列表
  private selectableCourses: SelectableCourse[] = [];
  // 选课记录
  private selectionRecords: CourseSelectionRecord[] = [];
  
  private constructor() {
    this.initializeMockData();
  }
  
  static getInstance(): CourseSelectionService {
    if (!CourseSelectionService.instance) {
      CourseSelectionService.instance = new CourseSelectionService();
    }
    return CourseSelectionService.instance;
  }
  
  // 初始化模拟数据
  private initializeMockData(): void {
    const now = Date.now();
    const oneDay = 24 * 60 * 60 * 1000;
    
    // 初始化选课时段
    this.selectionPeriods = [
      {
        id: 'period-1',
        name: '2024春季学期选课',
        semester: '2024春季',
        startTime: now - oneDay * 2,  // 2天前开始
        endTime: now + oneDay * 5,    // 5天后结束
        gradeRange: ['2022级', '2023级', '2024级'],
        isActive: true
      },
      {
        id: 'period-2',
        name: '2024秋季学期选课',
        semester: '2024秋季',
        startTime: now + oneDay * 30,  // 30天后开始
        endTime: now + oneDay * 35,    // 35天后结束
        gradeRange: ['2022级', '2023级', '2024级'],
        isActive: false
      }
    ];
    
    // 初始化可选课程
    this.selectableCourses = [
      {
        id: 'course-1',
        name: '高等数学',
        code: 'MATH101',
        teacherId: 'teacher-1',
        teacherName: '张教授',
        type: '必修',
        credit: 4,
        capacity: 60,
        selectedCount: 58,
        classroom: '教学楼A101',
        schedule: '周一 1-2节, 周三 1-2节',
        semester: '2024春季',
        description: '高等数学是理工科专业的基础课程'
      },
      {
        id: 'course-2',
        name: '线性代数',
        code: 'MATH102',
        teacherId: 'teacher-2',
        teacherName: '李教授',
        type: '必修',
        credit: 3,
        capacity: 50,
        selectedCount: 50,
        classroom: '教学楼A202',
        schedule: '周二 3-4节, 周四 3-4节',
        semester: '2024春季',
        description: '线性代数基础理论及应用'
      },
      {
        id: 'course-3',
        name: '程序设计基础',
        code: 'CS101',
        teacherId: 'teacher-3',
        teacherName: '王教授',
        type: '必修',
        credit: 3,
        capacity: 45,
        selectedCount: 40,
        classroom: '计算机楼B301',
        schedule: '周一 5-6节, 周五 3-4节',
        semester: '2024春季',
        description: '编程基础与算法入门'
      },
      {
        id: 'course-4',
        name: '数据结构',
        code: 'CS201',
        teacherId: 'teacher-4',
        teacherName: '赵教授',
        type: '必修',
        credit: 4,
        capacity: 40,
        selectedCount: 35,
        classroom: '计算机楼B302',
        schedule: '周三 5-6节, 周五 5-6节',
        semester: '2024春季',
        description: '数据结构与算法设计',
        prerequisites: ['CS101']
      },
      {
        id: 'course-5',
        name: '人工智能导论',
        code: 'AI101',
        teacherId: 'teacher-5',
        teacherName: '刘教授',
        type: '选修',
        credit: 2,
        capacity: 30,
        selectedCount: 28,
        classroom: '教学楼C401',
        schedule: '周四 7-8节',
        semester: '2024春季',
        description: '人工智能基础概念与应用'
      },
      {
        id: 'course-6',
        name: '机器学习',
        code: 'AI201',
        teacherId: 'teacher-6',
        teacherName: '陈教授',
        type: '选修',
        credit: 3,
        capacity: 25,
        selectedCount: 25,
        classroom: '教学楼C402',
        schedule: '周二 7-8节, 周四 5-6节',
        semester: '2024春季',
        description: '机器学习算法与实践',
        prerequisites: ['CS201', 'MATH101']
      },
      {
        id: 'course-7',
        name: '大学英语',
        code: 'ENG101',
        teacherId: 'teacher-7',
        teacherName: '孙老师',
        type: '公共基础',
        credit: 2,
        capacity: 60,
        selectedCount: 55,
        classroom: '教学楼D201',
        schedule: '周一 7-8节',
        semester: '2024春季',
        description: '大学英语四级辅导'
      }
    ];
    
    // 初始化选课记录（模拟已选课程）
    this.selectionRecords = [
      {
        id: 'record-1',
        studentId: '202401001',
        courseId: 'course-1',
        selectionTime: now - oneDay,
        status: SelectionStatus.SELECTED,
        semester: '2024春季'
      },
      {
        id: 'record-2',
        studentId: '202401001',
        courseId: 'course-3',
        selectionTime: now - oneDay,
        status: SelectionStatus.SELECTED,
        semester: '2024春季'
      }
    ];
  }
  
  // 获取当前激活的选课时段
  getActiveSelectionPeriod(): SelectionPeriod | null {
    return this.selectionPeriods.find(period => period.isActive) || null;
  }
  
  // 获取所有选课时段
  getAllSelectionPeriods(): SelectionPeriod[] {
    return this.selectionPeriods;
  }
  
  // 判断是否在选课时间内
  isInSelectionTime(periodId?: string): boolean {
    const now = Date.now();
    const period = periodId 
      ? this.selectionPeriods.find(p => p.id === periodId)
      : this.getActiveSelectionPeriod();
    
    if (!period) {
      return false;
    }
    
    return now >= period.startTime && now <= period.endTime;
  }
  
  // 判断是否在选课可见时间范围内（开始前30分钟到结束时间）
  isInSelectionVisibleTime(periodId?: string): boolean {
    const now = Date.now();
    const period = periodId 
      ? this.selectionPeriods.find(p => p.id === periodId)
      : this.getActiveSelectionPeriod();
    
    if (!period) {
      return false;
    }
    
    // 开始前30分钟
    const visibleStartTime = period.startTime - 30 * 60 * 1000;
    
    return now >= visibleStartTime && now <= period.endTime;
  }
  
  // 获取距离选课开始的剩余时间（毫秒）
  getTimeUntilSelectionStart(periodId?: string): number {
    const now = Date.now();
    const period = periodId 
      ? this.selectionPeriods.find(p => p.id === periodId)
      : this.getActiveSelectionPeriod();
    
    if (!period) {
      return -1;
    }
    
    return period.startTime - now;
  }
  
  // 获取选课时段状态
  getSelectionPeriodStatus(periodId?: string): SelectionStatus {
    const now = Date.now();
    const period = periodId 
      ? this.selectionPeriods.find(p => p.id === periodId)
      : this.getActiveSelectionPeriod();
    
    if (!period) {
      return SelectionStatus.NOT_STARTED;
    }
    
    if (now < period.startTime) {
      return SelectionStatus.NOT_STARTED;
    } else if (now > period.endTime) {
      return SelectionStatus.ENDED;
    } else {
      return SelectionStatus.IN_PROGRESS;
    }
  }
  
  // 获取可选课程列表（根据学期）
  getSelectableCourses(semester?: string): SelectableCourse[] {
    const targetSemester = semester || this.getActiveSelectionPeriod()?.semester;
    if (!targetSemester) {
      return [];
    }
    
    return this.selectableCourses.filter(course => course.semester === targetSemester);
  }
  
  // 获取学生已选课程
  getStudentSelectedCourses(studentId: string, semester?: string): CourseSelectionRecord[] {
    const targetSemester = semester || this.getActiveSelectionPeriod()?.semester;
    return this.selectionRecords.filter(
      record => record.studentId === studentId && 
                record.semester === targetSemester &&
                record.status === SelectionStatus.SELECTED
    );
  }
  
  // 实时验证选课是否有效
  validateSelection(studentId: string, courseId: string): SelectionValidation {
    const course = this.selectableCourses.find(c => c.id === courseId);
    
    if (!course) {
      return {
        isValid: false,
        status: SelectionStatus.NOT_STARTED,
        message: '课程不存在',
        canSelect: false
      };
    }
    
    // 检查是否在选课时间内
    if (!this.isInSelectionTime()) {
      const periodStatus = this.getSelectionPeriodStatus();
      return {
        isValid: false,
        status: periodStatus,
        message: periodStatus === SelectionStatus.NOT_STARTED 
          ? '选课尚未开始' 
          : '选课已结束',
        canSelect: false
      };
    }
    
    // 检查课程是否已满
    if (course.selectedCount >= course.capacity) {
      return {
        isValid: false,
        status: SelectionStatus.FULL,
        message: '该课程已满，无法选课',
        canSelect: false
      };
    }
    
    // 检查是否已选该课程
    const existingRecord = this.selectionRecords.find(
      record => record.studentId === studentId && 
                record.courseId === courseId &&
                record.status === SelectionStatus.SELECTED
    );
    
    if (existingRecord) {
      return {
        isValid: false,
        status: SelectionStatus.SELECTED,
        message: '您已选择该课程',
        canSelect: false
      };
    }
    
    // 检查先修课程
    if (course.prerequisites && course.prerequisites.length > 0) {
      const selectedCourses = this.getStudentSelectedCourses(studentId);
      const selectedCourseIds = selectedCourses.map(r => r.courseId);
      const unmetPrerequisites = course.prerequisites.filter(
        prereq => !selectedCourseIds.includes(prereq)
      );
      
      if (unmetPrerequisites.length > 0) {
        return {
          isValid: false,
          status: SelectionStatus.AVAILABLE,
          message: `缺少先修课程: ${unmetPrerequisites.join(', ')}`,
          canSelect: false
        };
      }
    }
    
    // 检查时间冲突
    const conflictResult = this.checkTimeConflict(studentId, course);
    if (conflictResult.hasConflict) {
      return {
        isValid: false,
        status: SelectionStatus.AVAILABLE,
        message: conflictResult.message,
        canSelect: false
      };
    }
    
    // 所有检查通过，可以选课
    return {
      isValid: true,
      status: SelectionStatus.AVAILABLE,
      message: '可以选课',
      canSelect: true
    };
  }
  
  // 解析课程时间字符串，返回时间段数组
  private parseSchedule(schedule: string): TimeSlot[] {
    const result: TimeSlot[] = [];
    const parts = schedule.split(',').map(p => p.trim());
    
    for (const part of parts) {
      // 格式: "周一 1-2节"
      const match = part.match(/(周[一二三四五六日])\s*(\d+-\d+节)/);
      if (match) {
        const day = match[1];
        const sectionStr = match[2];
        // 提取节次范围，如 "1-2节"
        const sectionMatch = sectionStr.match(/(\d+)-(\d+)节/);
        if (sectionMatch) {
          const start = parseInt(sectionMatch[1]);
          const end = parseInt(sectionMatch[2]);
          const sections: string[] = [];
          for (let i = start; i <= end; i++) {
            sections.push(`${i}节`);
          }
          result.push({ day: day, sections: sections });
        }
      }
    }
    
    return result;
  }
  
  // 检查时间冲突
  private checkTimeConflict(studentId: string, newCourse: SelectableCourse): TimeConflictResult {
    // 获取学生已选的所有课程
    const selectedRecords = this.selectionRecords.filter(
      record => record.studentId === studentId && 
                record.status === SelectionStatus.SELECTED &&
                record.semester === newCourse.semester
    );
    
    if (selectedRecords.length === 0) {
      return { hasConflict: false, message: '' };
    }
    
    // 解析新课程的时间
    const newSchedule = this.parseSchedule(newCourse.schedule);
    
    // 检查与每个已选课程的时间冲突
    for (const record of selectedRecords) {
      const existingCourse = this.selectableCourses.find(c => c.id === record.courseId);
      if (!existingCourse) continue;
      
      const existingSchedule = this.parseSchedule(existingCourse.schedule);
      
      // 检查每个时间段是否冲突
      for (const newTime of newSchedule) {
        for (const existingTime of existingSchedule) {
          // 同一天
          if (newTime.day === existingTime.day) {
            // 检查节次是否重叠
            for (const newSection of newTime.sections) {
              if (existingTime.sections.includes(newSection)) {
                return {
                  hasConflict: true,
                  message: `时间冲突：与已选课程"${existingCourse.name}"在${newTime.day} ${newSection}冲突`
                };
              }
            }
          }
        }
      }
    }
    
    return { hasConflict: false, message: '' };
  }
  
  // 选课操作
  selectCourse(studentId: string, courseId: string): boolean {
    const validation = this.validateSelection(studentId, courseId);
    
    if (!validation.canSelect) {
      return false;
    }
    
    const course = this.selectableCourses.find(c => c.id === courseId);
    if (!course) {
      return false;
    }
    
    // 创建选课记录
    const newRecord: CourseSelectionRecord = {
      id: `record-${Date.now()}`,
      studentId,
      courseId,
      selectionTime: Date.now(),
      status: SelectionStatus.SELECTED,
      semester: course.semester
    };
    
    this.selectionRecords.push(newRecord);
    
    // 更新课程已选人数
    course.selectedCount++;
    
    return true;
  }
  
  // 退课操作
  dropCourse(studentId: string, courseId: string): boolean {
    const recordIndex = this.selectionRecords.findIndex(
      record => record.studentId === studentId && 
                record.courseId === courseId &&
                record.status === SelectionStatus.SELECTED
    );
    
    if (recordIndex === -1) {
      return false;
    }
    
    // 删除选课记录
    this.selectionRecords.splice(recordIndex, 1);
    
    // 更新课程已选人数
    const course = this.selectableCourses.find(c => c.id === courseId);
    if (course && course.selectedCount > 0) {
      course.selectedCount--;
    }
    
    return true;
  }
  
  // 获取学生选课统计信息
  getStudentSelectionStats(studentId: string, semester?: string): SelectionStats {
    const selectedRecords = this.getStudentSelectedCourses(studentId, semester);
    const selectedCourseIds = selectedRecords.map(r => r.courseId);
    const selectedCourses = this.selectableCourses.filter(
      course => selectedCourseIds.includes(course.id)
    );
    
    return {
      totalCourses: this.getSelectableCourses(semester).length,
      selectedCourses: selectedCourses.length,
      requiredCourses: selectedCourses.filter(c => c.type === '必修').length,
      electiveCourses: selectedCourses.filter(c => c.type === '选修').length,
      totalCredits: selectedCourses.reduce((sum, c) => sum + c.credit, 0)
    };
  }
  
  // 获取课程详情
  getCourseById(courseId: string): SelectableCourse | undefined {
    return this.selectableCourses.find(c => c.id === courseId);
  }
  
  // 搜索课程
  searchCourses(keyword: string, semester?: string): SelectableCourse[] {
    const courses = this.getSelectableCourses(semester);
    if (!keyword.trim()) {
      return courses;
    }
    
    const lowerKeyword = keyword.toLowerCase();
    return courses.filter(course => 
      course.name.toLowerCase().includes(lowerKeyword) ||
      course.code.toLowerCase().includes(lowerKeyword) ||
      course.teacherName.toLowerCase().includes(lowerKeyword)
    );
  }
}
