import { 
  SelectionStatus, 
  SelectableCourse, 
  SelectionValidation,
  SelectionStats
} from '../models/CourseSelection';
import { CourseSelectionService } from '../services/CourseSelectionService';
import { AppStateManager } from '../services/AppStateManager';
import { DataService } from '../services/DataService';
import { router } from '@kit.ArkUI';

// 选课状态标签组件
@Component
struct SelectionStatusTag {
  @Prop status: SelectionStatus = SelectionStatus.AVAILABLE;
  
  build() {
    Text(this.status)
      .fontSize(12)
      .fontColor(this.getTagColor())
      .backgroundColor(this.getTagBgColor())
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .borderRadius(4)
  }
  
  private getTagColor(): string {
    switch (this.status) {
      case SelectionStatus.NOT_STARTED:
        return '#999999';
      case SelectionStatus.IN_PROGRESS:
        return '#1890FF';
      case SelectionStatus.ENDED:
        return '#FF4D4F';
      case SelectionStatus.FULL:
        return '#FF4D4F';
      case SelectionStatus.SELECTED:
        return '#52C41A';
      case SelectionStatus.AVAILABLE:
        return '#52C41A';
      default:
        return '#999999';
    }
  }
  
  private getTagBgColor(): string {
    switch (this.status) {
      case SelectionStatus.NOT_STARTED:
        return '#F5F5F5';
      case SelectionStatus.IN_PROGRESS:
        return '#E6F7FF';
      case SelectionStatus.ENDED:
        return '#FFF1F0';
      case SelectionStatus.FULL:
        return '#FFF1F0';
      case SelectionStatus.SELECTED:
        return '#F6FFED';
      case SelectionStatus.AVAILABLE:
        return '#F6FFED';
      default:
        return '#F5F5F5';
    }
  }
}

// 课程卡片组件
@Component
struct CourseCard {
  @Prop course: SelectableCourse = {} as SelectableCourse;
  @Prop validation: SelectionValidation = {} as SelectionValidation;
  @Prop isSelected: boolean = false;
  @Prop isInSelectionTime: boolean = false;
  onSelect: () => void = () => {};
  onDropCourse: () => void = () => {};
  
  build() {
    Column() {
      // 课程基本信息
      Row() {
        Column() {
          Row() {
            Text(this.course.name)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
            
            Blank()
            
            SelectionStatusTag({ status: this.getStatus() })
          }
          .width('100%')
          
          Row() {
            Text(`${this.course.code} | ${this.course.type}`)
              .fontSize(12)
              .fontColor('#666666')
          }
          .margin({ top: 4 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      
      // 课程详细信息
      Column() {
        Row() {
          Text('授课教师：')
            .fontSize(13)
            .fontColor('#999999')
          Text(this.course.teacherName)
            .fontSize(13)
            .fontColor('#333333')
        }
        
        Row() {
          Text('上课时间：')
            .fontSize(13)
            .fontColor('#999999')
          Text(this.course.schedule)
            .fontSize(13)
            .fontColor('#333333')
        }
        .margin({ top: 6 })
        
        Row() {
          Text('上课地点：')
            .fontSize(13)
            .fontColor('#999999')
          Text(this.course.classroom)
            .fontSize(13)
            .fontColor('#333333')
        }
        .margin({ top: 6 })
        
        Row() {
          Text('学分：')
            .fontSize(13)
            .fontColor('#999999')
          Text(`${this.course.credit}`)
            .fontSize(13)
            .fontColor('#333333')
          
          Blank()
          
          Text('容量：')
            .fontSize(13)
            .fontColor('#999999')
          Text(`${this.course.selectedCount}/${this.course.capacity}`)
            .fontSize(13)
            .fontColor(this.course.selectedCount >= this.course.capacity ? '#FF4D4F' : '#333333')
        }
        .width('100%')
        .margin({ top: 6 })
      }
      .width('100%')
      .margin({ top: 12 })
      
      // 验证提示信息
      if (!this.validation.isValid && !this.isSelected) {
        Row() {
          Text(`⚠ ${this.validation.message}`)
            .fontSize(12)
            .fontColor('#FF4D4F')
        }
        .width('100%')
        .margin({ top: 8 })
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#FFF1F0')
        .borderRadius(4)
      }
      
      // 操作按钮
      Row() {
        if (this.isSelected) {
          Button('退课')
            .fontSize(14)
            .fontColor('#FF4D4F')
            .backgroundColor('#FFF1F0')
            .borderRadius(4)
            .width(80)
            .height(32)
            .onClick(() => this.onDropCourse())
        } else {
          Button('选课')
            .fontSize(14)
            .fontColor(this.validation.canSelect ? '#FFFFFF' : '#999999')
            .backgroundColor(this.validation.canSelect ? '#1890FF' : '#F5F5F5')
            .borderRadius(4)
            .width(80)
            .height(32)
            .enabled(this.validation.canSelect)
            .onClick(() => this.onSelect())
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 2, color: '#00000010', offsetX: 0, offsetY: 1 })
  }
  
  private getStatus(): SelectionStatus {
    if (this.isSelected) {
      return SelectionStatus.SELECTED;
    }
    if (this.course.selectedCount >= this.course.capacity) {
      return SelectionStatus.FULL;
    }
    return this.validation.status;
  }
}

// 主页面
@Component
export struct CourseSelectionPage {
  @State currentStudentId: string = '';  // 当前学生ID
  @State searchKeyword: string = '';
  @State courses: SelectableCourse[] = [];
  @State selectedCourseIds: string[] = [];
  @State stats: SelectionStats = {
    totalCourses: 0,
    selectedCourses: 0,
    requiredCourses: 0,
    electiveCourses: 0,
    totalCredits: 0
  };
  @State isInSelectionTime: boolean = false;
  @State isInVisibleTime: boolean = false;  // 是否在选课可见时间范围内
  @State selectionPeriodStatus: SelectionStatus = SelectionStatus.NOT_STARTED;
  @State periodName: string = '';
  
  private selectionService: CourseSelectionService = CourseSelectionService.getInstance();
  private dataService: DataService = DataService.getInstance();
  
  aboutToAppear(): void {
    // 获取当前用户ID
    const currentUser = this.dataService.getCurrentUser();
    if (currentUser) {
      this.currentStudentId = currentUser.id;
    }
    this.loadData();
  }
  
  private loadData(): void {
    // 获取选课时段信息
    const period = this.selectionService.getActiveSelectionPeriod();
    if (period) {
      this.periodName = period.name;
      this.isInSelectionTime = this.selectionService.isInSelectionTime();
      this.isInVisibleTime = this.selectionService.isInSelectionVisibleTime();
      this.selectionPeriodStatus = this.selectionService.getSelectionPeriodStatus();
    }
    
    // 只有在可见时间范围内才加载课程数据
    if (this.isInVisibleTime) {
      // 获取可选课程列表
      this.courses = this.selectionService.searchCourses(this.searchKeyword);
      
      // 获取已选课程
      const selectedRecords = this.selectionService.getStudentSelectedCourses(this.currentStudentId);
      this.selectedCourseIds = selectedRecords.map(r => r.courseId);
      
      // 获取统计信息
      this.stats = this.selectionService.getStudentSelectionStats(this.currentStudentId);
    } else {
      // 不在可见时间范围内，清空课程列表
      this.courses = [];
      this.selectedCourseIds = [];
    }
  }
  
  private handleSelectCourse(courseId: string): void {
    const success = this.selectionService.selectCourse(this.currentStudentId, courseId);
    if (success) {
      // 获取课程名称
      const course = this.selectionService.getCourseById(courseId);
      if (course) {
        // 使用AlertDialog显示成功提示
        AlertDialog.show({
          title: '✅ 选课成功',
          message: `恭喜！您已成功选择课程：${course.name}`,
          autoCancel: true,
          alignment: DialogAlignment.Center,
          confirm: {
            value: '确定',
            fontColor: '#1890FF',
            action: () => {}
          }
        });
      }
      this.loadData();  // 刷新数据
    } else {
      // 可以添加错误提示
      console.error('选课失败');
    }
  }
  
  private handleDropCourse(courseId: string): void {
    // 获取课程名称用于确认提示
    const course = this.selectionService.getCourseById(courseId);
    if (!course) {
      console.error('课程不存在');
      return;
    }
    
    // 显示退课确认对话框
    AlertDialog.show({
      title: '⚠️ 退课确认',
      message: `您确定要退选课程"${course.name}"吗？\n退课后需要重新选课。`,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        fontColor: '#666666',
        action: () => {}
      },
      secondaryButton: {
        value: '确定退课',
        fontColor: '#FF4D4F',
        action: () => {
          // 执行退课操作
          const success = this.selectionService.dropCourse(this.currentStudentId, courseId);
          if (success) {
            // 显示退课成功提示
            AlertDialog.show({
              title: '✅ 退课成功',
              message: `您已成功退选课程：${course.name}`,
              autoCancel: true,
              alignment: DialogAlignment.Center,
              confirm: {
                value: '确定',
                fontColor: '#1890FF',
                action: () => {}
              }
            });
            this.loadData();  // 刷新数据
          } else {
            console.error('退课失败');
          }
        }
      }
    });
  }
  
  private getValidation(courseId: string): SelectionValidation {
    return this.selectionService.validateSelection(this.currentStudentId, courseId);
  }
  
  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('学生选课')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
        
        Button('查看课表')
          .height(32)
          .fontSize(14)
          .fontColor('#007AFF')
          .backgroundColor('#E5F3FF')
          .borderRadius(8)
          .onClick(() => {
            router.pushUrl({ url: 'pages/SchedulePage' });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor('#FFFFFF')
      
      Scroll() {
        Column() {
          // 选课时段状态卡片
          Column() {
            Row() {
              Text(this.periodName || '暂无选课时段')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A1A')
              
              Blank()
              
              SelectionStatusTag({ status: this.selectionPeriodStatus })
            }
            .width('100%')
            
            if (!this.isInSelectionTime) {
              Row() {
                Text(this.selectionPeriodStatus === SelectionStatus.NOT_STARTED 
                  ? '选课尚未开始，请耐心等待' 
                  : '选课已结束')
                  .fontSize(13)
                  .fontColor('#FF4D4F')
              }
              .width('100%')
              .margin({ top: 8 })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ top: 12, left: 16, right: 16 })
          
          // 根据是否在选课可见时间范围内显示不同内容
          if (!this.isInVisibleTime) {
            // 不在选课可见时间范围内，显示提示信息
            Column() {
              Column() {
                Text('⏰')
                  .fontSize(48)
                
                Text('选课时间未到，无法选课')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A1A1A')
                  .margin({ top: 16 })
                
                Text('选课将在开始前30分钟开放，请耐心等待')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ top: 8 })
              }
              .width('100%')
              .padding(32)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .padding({ left: 16, right: 16 })
          } else {
            // 在选课可见时间范围内，显示课程列表
            // 已选课程统计
            Column() {
              Row() {
                Text('已选课程统计')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A1A1A')
              }
              .width('100%')
              
              Row() {
                Column() {
                  Text(`${this.stats.selectedCourses}`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1890FF')
                  Text('已选课程')
                    .fontSize(12)
                    .fontColor('#666666')
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                
                Column() {
                  Text(`${this.stats.requiredCourses}`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#52C41A')
                  Text('必修课')
                    .fontSize(12)
                    .fontColor('#666666')
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                
                Column() {
                  Text(`${this.stats.electiveCourses}`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FAAD14')
                  Text('选修课')
                    .fontSize(12)
                    .fontColor('#666666')
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                
                Column() {
                  Text(`${this.stats.totalCredits}`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#722ED1')
                  Text('总学分')
                    .fontSize(12)
                    .fontColor('#666666')
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
              }
              .width('100%')
              .margin({ top: 16 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ top: 12, left: 16, right: 16 })
            
            // 搜索栏
            Row() {
              TextInput({ placeholder: '搜索课程名称、代码或教师' })
                .fontSize(14)
                .layoutWeight(1)
                .height(40)
                .backgroundColor('#F5F5F5')
                .borderRadius(20)
                .onChange((value: string) => {
                  this.searchKeyword = value;
                  this.courses = this.selectionService.searchCourses(value);
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
            .margin({ top: 12 })
            
            // 课程列表
            Column() {
              Row() {
                Text(`可选课程 (${this.courses.length})`)
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A1A1A')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12 })
              
              if (this.courses.length === 0) {
                Column() {
                  Text('暂无可选课程')
                    .fontSize(14)
                    .fontColor('#999999')
                }
                .width('100%')
                .height(200)
                .justifyContent(FlexAlign.Center)
              } else {
                ForEach(this.courses, (course: SelectableCourse) => {
                  CourseCard({
                    course: course,
                    validation: this.getValidation(course.id),
                    isSelected: this.selectedCourseIds.includes(course.id),
                    isInSelectionTime: this.isInSelectionTime,
                    onSelect: () => this.handleSelectCourse(course.id),
                    onDropCourse: () => this.handleDropCourse(course.id)
                  })
                  .margin({ top: 12, left: 16, right: 16 })
                }, (course: SelectableCourse) => course.id)
              }
            }
            .width('100%')
            .margin({ top: 12 })
          }
        }
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
