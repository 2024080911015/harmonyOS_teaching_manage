import { LeaveRequestDialog } from "../components/LeaveRequestDialog";
import { DataService } from "../services/DataService";
import { AppStateManager } from "../services/AppStateManager";
import { User, UserRole, CourseSchedule, CourseStatus } from "../models/DataModels";
import { router } from "@kit.ArkUI";

// 课程单元格数据
interface ScheduleCell {
  course?: CourseSchedule;
  timeSlot: string;
  weekDay: number;
}

// 时间段定义
const TIME_SLOTS = [
  '第1-2节\n8:00-9:40',
  '第3-4节\n10:00-11:40',
  '第5-6节\n14:00-15:40',
  '第7-8节\n16:00-17:40',
  '第9-10节\n19:00-20:40'
];

// 星期定义
const WEEK_DAYS = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

@Entry
@Component
export struct SchedulePage {
  @State currentUser: User | null = null;
  @State courses: CourseSchedule[] = [];
  @State showLeaveDialog: boolean = false;
  @State selectedCourse: CourseSchedule | null = null;
  @State currentWeek: number = 1;
  @State totalWeeks: number = 20;
  
  private dataService: DataService = DataService.getInstance();
  private appStateManager: AppStateManager = AppStateManager.getInstance();
  
  aboutToAppear(): void {
    this.currentUser = this.dataService.getCurrentUser();
    this.loadCourses();
  }
  
  // 页面显示时刷新数据
  onPageShow(): void {
    this.loadCourses();
  }
  
  // 加载课程数据
  loadCourses(): void {
    if (this.currentUser) {
      if (this.currentUser.role === UserRole.STUDENT) {
        // 学生获取自己的课程表
        this.courses = this.dataService.getStudentCourses(this.currentUser.id);
      } else if (this.currentUser.role === UserRole.TEACHER) {
        // 教师获取自己的课程表
        this.courses = this.dataService.getTeacherCourses(this.currentUser.id);
      }
    }
  }
  
  // 获取指定时间段的课程
  getCourseByTimeSlot(weekDay: number, timeSlotIndex: number): CourseSchedule | undefined {
    return this.courses.find(course => {
      // 简化的时间匹配逻辑
      const schedule = course.schedule;
      if (schedule.includes(WEEK_DAYS[weekDay])) {
        // 检查时间段是否匹配
        const timeSlotStr = TIME_SLOTS[timeSlotIndex].split('\n')[0];
        return schedule.includes(timeSlotStr);
      }
      return false;
    });
  }
  
  // 处理课程点击
  onCourseClick(course: CourseSchedule): void {
    this.selectedCourse = course;
    if (this.currentUser?.role === UserRole.STUDENT) {
      // 学生点击课程，弹出请假对话框
      this.showLeaveDialog = true;
    }
  }
  
  // 请假成功回调
  onLeaveSuccess(): void {
    this.showLeaveDialog = false;
    this.selectedCourse = null;
  }
  
  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button('←')
          .width(40)
          .height(40)
          .fontSize(20)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.back();
          })
        
        Text('我的课表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .margin({ left: 8 })
        
        Blank()
        
        // 周数选择器
        Row() {
          Button('<')
            .width(30)
            .height(30)
            .fontSize(14)
            .onClick(() => {
              if (this.currentWeek > 1) {
                this.currentWeek--;
              }
            })
          
          Text(`第${this.currentWeek}周`)
            .fontSize(16)
            .fontColor('#007AFF')
            .margin({ left: 10, right: 10 })
          
          Button('>')
            .width(30)
            .height(30)
            .fontSize(14)
            .onClick(() => {
              if (this.currentWeek < this.totalWeeks) {
                this.currentWeek++;
              }
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')
      
      // 请假功能入口（学生端）
      if (this.currentUser?.role === UserRole.STUDENT) {
        Row() {
          Button('申请请假')
            .height(40)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#007AFF')
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => {
              this.selectedCourse = null;
              this.showLeaveDialog = true;
            })
          
          Button('选课')
            .height(40)
            .fontSize(16)
            .fontColor('#007AFF')
            .backgroundColor('#E5F3FF')
            .borderRadius(8)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/CourseSelectionPage' });
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')
      }
      
      // 课表网格
      Column() {
        // 表头：星期
        Row() {
          Text('时间')
            .width('15%')
            .fontSize(12)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
          
          ForEach(WEEK_DAYS, (day: string, index: number) => {
            Text(day)
              .width(`${85 / 7}%`)
              .fontSize(12)
              .fontColor('#666666')
              .textAlign(TextAlign.Center)
          })
        }
        .width('100%')
        .height(40)
        .backgroundColor('#F5F5F5')
        
        // 课程网格
        ForEach(TIME_SLOTS, (timeSlot: string, timeSlotIndex: number) => {
          Row() {
            // 时间列
            Text(timeSlot)
              .width('15%')
              .fontSize(10)
              .fontColor('#666666')
              .textAlign(TextAlign.Center)
            
            // 课程列
            ForEach([0, 1, 2, 3, 4, 5, 6], (weekDay: number) => {
              Column() {
                if (this.getCourseByTimeSlot(weekDay, timeSlotIndex)) {
                  Text(this.getCourseByTimeSlot(weekDay, timeSlotIndex)!.name)
                    .fontSize(10)
                    .fontColor('#FFFFFF')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
              }
              .width(`${85 / 7}%`)
              .height(60)
              .backgroundColor(this.getCourseByTimeSlot(weekDay, timeSlotIndex) ? '#007AFF' : 'transparent')
              .borderRadius(4)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                const course = this.getCourseByTimeSlot(weekDay, timeSlotIndex);
                if (course) {
                  this.onCourseClick(course);
                }
              })
            })
          }
          .width('100%')
          .height(60)
        })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')
      .margin({ top: 8 })
      
      // 课程列表（简化显示）
      Column() {
        Text('本周课程')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .width('100%')
          .padding({ left: 16, top: 12, bottom: 8 })
        
        if (this.courses.length === 0) {
          Text('暂无课程数据')
            .fontSize(14)
            .fontColor('#999999')
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding(20)
        } else {
          ForEach(this.courses, (course: CourseSchedule) => {
            Row() {
              Column() {
                Text(course.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A1A1A')
                
                Text(`${course.schedule} | ${course.classroom}`)
                  .fontSize(12)
                  .fontColor('#666666')
                  .margin({ top: 4 })
                
                Text(`教师: ${course.teacherName}`)
                  .fontSize(12)
                  .fontColor('#666666')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              
              // 学生端显示请假按钮
              if (this.currentUser?.role === UserRole.STUDENT) {
                Button('请假')
                  .height(32)
                  .fontSize(12)
                  .fontColor('#007AFF')
                  .backgroundColor('#E5F3FF')
                  .borderRadius(4)
                  .onClick(() => {
                    this.selectedCourse = course;
                    this.showLeaveDialog = true;
                  })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ bottom: 8 })
          })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F8F9FA')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
    .bindSheet($$this.showLeaveDialog, this.leaveSheetBuilder(), {
      height: '80%',
      backgroundColor: Color.White,
      dragBar: true
    })
  }
  
  @Builder
  leaveSheetBuilder() {
    Column() {
      // 标题
      Row() {
        Text('申请请假')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
        
        Button('关闭')
          .height(32)
          .fontSize(14)
          .fontColor('#666666')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showLeaveDialog = false;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      
      // 请假表单
      LeaveRequestDialog({
        isVisible: this.showLeaveDialog,
        studentId: this.currentUser?.id || '',
        studentName: this.currentUser?.name || '',
        className: '',
        onSuccess: () => {
          this.onLeaveSuccess();
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
