import { SearchBar, EmptyState, StatusTag } from "../components/CommonComponents";
import { LeaveRequestDialog } from "../components/LeaveRequestDialog";
import { Course, CourseType } from "../models/AppModels";
import { DataService } from "../services/DataService";
import { AppStateManager } from "../services/AppStateManager";
import { User, UserRole, CourseSchedule } from "../models/DataModels";

interface SelectOption {
  value: string;
}

@Entry
@Component
export struct CourseManagementPage {
  @State courses: Course[] = [];
  @State filteredCourses: Course[] = [];
  @State searchText: string = '';
  @State selectedSemester: string = '';
  @State semesters: string[] = [];
  @State currentUser: User | null = null;
  @State showLeaveRequestDialog: boolean = false;
  @State hasActiveLeave: boolean = false;

  private dataService: DataService = DataService.getInstance();
  private appState: AppStateManager = AppStateManager.getInstance();

  aboutToAppear(): void {
    this.currentUser = this.appState.getCurrentUser() as User;
    this.loadData();
    this.checkActiveLeave();
  }
  
  // 检查是否有未完成的请假
  checkActiveLeave(): void {
    if (this.currentUser && this.currentUser.role === UserRole.STUDENT) {
      this.hasActiveLeave = this.dataService.hasActiveLeaveRequest(this.currentUser.id);
      console.info('检查是否有未完成的请假: ' + this.hasActiveLeave);
    }
  }

  loadData(): void {
    // 根据用户角色获取课程
    if (this.currentUser) {
      if (this.currentUser.role === UserRole.TEACHER) {
        // 教师：只显示自己教授的课程
        const teacherCourses = this.dataService.getTeacherCourses(this.currentUser.id);
        this.courses = this.convertToAppCourses(teacherCourses);
      } else if (this.currentUser.role === UserRole.STUDENT) {
        // 学生：只显示自己选修的课程
        const studentCourses = this.dataService.getStudentCourses(this.currentUser.id);
        this.courses = this.convertToAppCourses(studentCourses);
      } else {
        // 教务处/学院领导：显示所有课程
        this.courses = this.dataService.getAllCourses();
      }
    } else {
      this.courses = this.dataService.getAllCourses();
    }
    
    this.filteredCourses = [...this.courses];

    // 获取所有学期
    const semesterSet = new Set<string>();
    this.courses.forEach(c => semesterSet.add(c.semester));
    this.semesters = Array.from(semesterSet);
    if (this.semesters.length > 0) {
      this.selectedSemester = this.semesters[0];
    }
  }
  
  // 将DataModels的CourseSchedule转换为AppModels的Course
  convertToAppCourses(courses: CourseSchedule[]): Course[] {
    const result: Course[] = [];
    for (let i = 0; i < courses.length; i++) {
      const c = courses[i];
      const converted: Course = {
        id: c.id,
        name: c.name,
        credit: c.credit,
        type: CourseType.REQUIRED,
        department: c.department,
        teacher: c.teacherName,
        syllabus: '',
        semester: '2025-2026学年第一学期',
        grade: '2024级',
        major: '计算机科学与技术',
        makeUpExam: false
      };
      result.push(converted);
    }
    return result;
  }

  build() {
    Stack() {
      Column() {
        // 标题
        Text('课程管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .padding({ left: 16, top: 12, bottom: 8 })
          .width('100%')
      
      // 学生端请假功能入口
      if (this.currentUser && this.currentUser.role === UserRole.STUDENT) {
        Row() {
          Button('申请请假')
            .height(36)
            .fontSize(14)
            .fontColor('#007AFF')
            .backgroundColor('#E5F3FF')
            .borderRadius(8)
            .onClick(() => {
              console.info('申请请假按钮被点击');
              this.showLeaveRequestDialog = true;
              console.info('showLeaveRequestDialog设置为: ' + this.showLeaveRequestDialog);
            })
          
          Blank()
          
          Button('我的请假')
            .height(36)
            .fontSize(14)
            .fontColor('#007AFF')
            .backgroundColor('#E5F3FF')
            .borderRadius(8)
            .onClick(() => {
              // 导航到请假管理页面
              console.info('导航到请假管理页面');
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        
        if (this.hasActiveLeave) {
          Text('您有未完成的请假，需完成销假后才能申请新请假')
            .fontSize(12)
            .fontColor('#FF9500')
            .padding({ left: 16, right: 16, bottom: 8 })
        }
      }

      // 学期筛选
      Row() {
        Text('学期:')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ right: 8 })

        if (this.semesters.length > 0) {
          Select([
            ...this.semesters.map((s: string): SelectOption => { return { value: s } })
          ])
            .selected(this.semesters.indexOf(this.selectedSemester))
            .value(this.selectedSemester)
            .fontColor('#007AFF')
            .backgroundColor('#F0F7FF')
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .onSelect((index: number) => {
              this.selectedSemester = this.semesters[index];
              this.filterCourses();
            })
        }
        Blank()
        Text(`共 ${this.filteredCourses.length} 门课程`)
          .fontSize(13)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 8 })

      // 搜索栏
      SearchBar({
        placeholder: '搜索课程（代码/名称/教研室）',
        searchText: $searchText,
        onSearch: (text: string) => {
          this.filterCourses();
        }
      })
        .padding({ left: 16, right: 16, bottom: 8 })

      // 课程列表
      if (this.filteredCourses.length > 0) {
        List() {
          ForEach(this.filteredCourses, (course: Course, index: number) => {
            ListItem() {
              this.CourseItem(course)
            }
          }, (course: Course) => course.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 8 })
      } else {
        EmptyState({ text: this.searchText ? '未找到匹配的课程' : '暂无课程数据' })
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
    
    // 请假申请对话框
    LeaveRequestDialog({
      isVisible: $showLeaveRequestDialog,
      studentId: this.currentUser?.id || '',
      studentName: this.currentUser?.name || '',
      className: '', // 需要从用户信息中获取班级名称
      onSuccess: () => {
        this.onLeaveRequestSuccess();
      }
    })
  }
    .width('100%')
    .height('100%')
  }

  @Builder
  CourseItem(course: Course) {
    Column() {
      Row() {
        Column() {
          Text(course.id)
            .fontSize(12)
            .fontColor('#007AFF')
            .backgroundColor('#E8F2FF')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(4)
          Text(course.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        StatusTag({
          text: course.type,
          type: course.type === '必修' ? 'success' : course.type === '选修' ? 'warning' : 'default'
        })
      }
      .width('100%')

      Row() {
        Text(`📚 ${course.department}`)
          .fontSize(13)
          .fontColor('#666666')
        Text(' | ')
          .fontSize(13)
          .fontColor('#666666')
        Text(`👨‍🏫 ${course.teacher}`)
          .fontSize(13)
          .fontColor('#666666')
        Text(' | ')
          .fontSize(13)
          .fontColor('#666666')
        Text(`📖 ${course.credit}学分`)
          .fontSize(13)
          .fontColor('#666666')
      }
      .margin({ top: 6 })
      .width('100%')

      Row() {
        if (course.makeUpExam) {
          StatusTag({ text: '参与补考', type: 'warning' })
        } else {
          StatusTag({ text: '不参与补考', type: 'default' })
        }
        Blank()
        Text(course.semester)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 8 })
    .shadow({ radius: 3, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: 1 })
  }

  private filterCourses(): void {
    let result = [...this.courses];

    // 学期筛选
    if (this.selectedSemester) {
      result = result.filter(c => c.semester === this.selectedSemester);
    }

    // 搜索关键词
    if (this.searchText.trim()) {
      const keyword = this.searchText.toLowerCase();
      result = result.filter(c =>
      c.id.toLowerCase().includes(keyword) ||
        c.name.includes(this.searchText) ||
        c.department.includes(this.searchText) ||
        c.teacher.includes(this.searchText)
      );
    }

    this.filteredCourses = result;
  }
  
  // 处理请假申请成功
  private onLeaveRequestSuccess(): void {
    this.checkActiveLeave();
  }
}