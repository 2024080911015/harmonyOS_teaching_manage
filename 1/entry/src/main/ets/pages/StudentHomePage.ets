import { showConfirmDialog, EmptyState, StatusTag, InfoCard } from "../components/CommonComponents";
import { Student, Class, LessonPlan, Attachment } from "../models/AppModels";
import { AppStateManager } from "../services/AppStateManager";
import { DataService } from "../services/DataService";
import { router } from "@kit.ArkUI";

@Entry
@Component
export struct StudentHomePage {
  @State studentInfo: Student | null = null;
  @State classInfo: Class | null = null;
  @State lessonPlans: LessonPlan[] = [];
  @State classmates: Student[] = [];
  @State showLessonPlanDetail: boolean = false;
  @State selectedLessonPlan: LessonPlan | null = null;

  private appState: AppStateManager = AppStateManager.getInstance();
  private dataService: DataService = DataService.getInstance();

  aboutToAppear(): void {
    this.loadData();
  }

  loadData(): void {
    const student = this.appState.getCurrentUser() as Student;
    if (student) {
      this.studentInfo = student;
      const cls = this.dataService.getClassById(student.classId);
      if (cls) {
        this.classInfo = cls;
        this.classmates = cls.students.filter(s => s.id !== student.id) || [];
      }
      this.lessonPlans = this.dataService.getLessonPlansByClass(student.classId);
    }
  }

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('学生端 · 我的信息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
        Blank()
        Button('我的课表')
          .fontSize(12)
          .fontColor('#007AFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.pushUrl({ url: 'pages/SchedulePage' });
          })
        Button('退出登录')
          .fontSize(12)
          .fontColor('#FF3B30')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            showConfirmDialog('确认退出', '确定要退出登录吗？', () => {
              this.appState.logout();
              router.replaceUrl({ url: 'pages/LoginPage' });
            });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // 个人信息卡片
      if (this.studentInfo && !this.showLessonPlanDetail) {
        this.PersonalInfoCard(this.studentInfo)
      }

      // 班级信息
      if (this.classInfo && !this.showLessonPlanDetail) {
        this.ClassSummaryCard(this.classInfo)
      }

      // 班级成员
      if (!this.showLessonPlanDetail) {
        Column() {
          Row() {
            Text('班级成员')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')
            Blank()
            Text(`共 ${this.classmates.length + 1} 人`)
              .fontSize(13)
              .fontColor('#999999')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 4 })

          if (this.classmates.length > 0) {
            List() {
              ForEach(this.classmates, (student: Student, index: number) => {
                ListItem() {
                  this.ClassmateItem(student)
                }
              }, (student: Student) => student.id)
            }
            .width('100%')
            .height(200)
            .padding({ left: 16, right: 16 })
          } else {
            EmptyState({ text: '暂无其他同学' })
              .height(120)
          }
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ left: 16, right: 16, top: 8 })
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: 2 })
        .layoutWeight(1)
      }

      // 教案查看
      Column() {
        if (!this.showLessonPlanDetail) {
          // 教案列表
          Row() {
            Text('📖 班级教案')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A1A')
            Blank()
            Text(`${this.lessonPlans.length} 份`)
              .fontSize(13)
              .fontColor('#999999')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 4 })

          if (this.lessonPlans.length > 0) {
            List() {
              ForEach(this.lessonPlans, (plan: LessonPlan, index: number) => {
                ListItem() {
                  this.LessonPlanItem(plan)
                }
              }, (plan: LessonPlan) => plan.id)
            }
            .width('100%')
            .height(160)
            .padding({ left: 16, right: 16 })
          } else {
            EmptyState({ text: '暂无教案' })
              .height(120)
          }
        } else {
          // 教案详情
          if (this.selectedLessonPlan) {
            Column() {
              // 标题栏
              Row() {
                Button('← 返回')
                  .fontSize(14)
                  .fontColor('#1a73e8')
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    this.showLessonPlanDetail = false;
                    this.selectedLessonPlan = null;
                  })
                
                Blank()
                
                Text('教案详情')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1A1A1A')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              
              // 详情内容
              Scroll() {
                Column() {
                  Text(this.selectedLessonPlan.title)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                    .width('100%')
                    .margin({ bottom: 16 })
                  
                  Row() {
                    Text(`教师：${this.selectedLessonPlan.teacherName}`)
                      .fontSize(14)
                      .fontColor('#666666')
                  }
                  .width('100%')
                  .margin({ bottom: 12 })
                  
                  Text('内容：')
                    .fontSize(14)
                    .fontColor('#666666')
                    .width('100%')
                    .margin({ bottom: 8 })
                  
                  Text(this.selectedLessonPlan.content)
                    .fontSize(14)
                    .fontColor('#333333')
                    .width('100%')
                    .lineHeight(22)
                    .margin({ bottom: 16 })
                  
                  if (this.selectedLessonPlan.attachments.length > 0) {
                    Text('附件：')
                      .fontSize(14)
                      .fontColor('#666666')
                      .width('100%')
                      .margin({ bottom: 8 })
                    
                    Column() {
                      ForEach(this.selectedLessonPlan.attachments, (attachment: Attachment) => {
                        Row() {
                          Text('📎 ' + attachment.name)
                            .fontSize(14)
                            .fontColor('#1a73e8')
                        }
                        .width('100%')
                        .padding(8)
                        .backgroundColor('#f5f5f5')
                        .borderRadius(4)
                        .margin({ bottom: 4 })
                      }, (attachment: Attachment) => attachment.id)
                    }
                    .width('100%')
                  }
                  
                  Text(`上传时间：${this.selectedLessonPlan.uploadTime}`)
                    .fontSize(12)
                    .fontColor('#999999')
                    .width('100%')
                    .margin({ top: 16 })
                }
                .width('100%')
                .padding({ left: 16, right: 16, bottom: 16 })
              }
              .width('100%')
              .layoutWeight(1)
              .scrollBar(BarState.Auto)
              .edgeEffect(EdgeEffect.Spring)
            }
            .width('100%')
            .layoutWeight(1)
          }
        }
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(12)
      .margin({ left: 16, right: 16, top: 8, bottom: 12 })
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: 2 })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  PersonalInfoCard(student: Student) {
    Row() {
      Column() {
        Text(student.name.charAt(0))
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width(64)
      .height(64)
      .backgroundColor('#007AFF')
      .borderRadius(32)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Row() {
          Text(student.name)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
          Blank()
          StatusTag({ text: student.position || '学生', type: student.position === '班长' ? 'warning' : 'default' })
        }
        .width('100%')

        Row() {
          Text(`学号: ${student.id}`)
            .fontSize(14)
            .fontColor('#666666')
          Text(' | ')
            .fontSize(14)
            .fontColor('#666666')
          Text(`性别: ${student.gender}`)
            .fontSize(14)
            .fontColor('#666666')
          Text(' | ')
            .fontSize(14)
            .fontColor('#666666')
          Text(`年级: ${student.grade}`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .margin({ top: 4 })
        .width('100%')

        Row() {
          Text(`班级: ${student.className}`)
            .fontSize(14)
            .fontColor('#666666')
          Text(' | ')
            .fontSize(14)
            .fontColor('#666666')
          Text(`专业: ${student.major}`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .margin({ top: 2 })
        .width('100%')
      }
      .layoutWeight(1)
      .margin({ left: 16 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 8 })
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: 2 })
  }

  @Builder
  ClassSummaryCard(cls: Class) {
    Row() {
      InfoCard({
        title: '班级',
        content: cls.name,
        icon: $r('app.media.ic_class'),
        showArrow: false
      })
        .layoutWeight(1)

      InfoCard({
        title: '辅导员',
        content: cls.headTeacher,
        icon: $r('app.media.ic_teacher'),
        showArrow: false
      })
        .layoutWeight(1)
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  ClassmateItem(student: Student) {
    Row() {
      Column() {
        Text(student.name.charAt(0))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width(32)
      .height(32)
      .backgroundColor('#34C759')
      .borderRadius(16)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(student.name)
        .fontSize(14)
        .fontColor('#1A1A1A')
        .margin({ left: 10 })
        .layoutWeight(1)

      Text(student.position || '学生')
        .fontSize(12)
        .fontColor('#999999')
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .borderRadius(6)
  }

  @Builder
  LessonPlanItem(plan: LessonPlan) {
    Column() {
      Row() {
        Text(plan.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
        Blank()
        Text(plan.uploadTime)
          .fontSize(11)
          .fontColor('#999999')
      }
      .width('100%')

      Text(plan.content.length > 50 ? plan.content.substring(0, 50) + '...' : plan.content)
        .fontSize(13)
        .fontColor('#666666')
        .margin({ top: 4 })
        .width('100%')
        .maxLines(2)

      Row() {
        Text(`👨‍🏫 ${plan.teacherName}`)
          .fontSize(12)
          .fontColor('#999999')
        Blank()
        if (plan.attachments.length > 0) {
          Text(`📎 ${plan.attachments.length}个附件`)
            .fontSize(12)
            .fontColor('#007AFF')
        }
      }
      .width('100%')
      .margin({ top: 6 })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor('#F8F9FA')
    .borderRadius(8)
    .margin({ bottom: 6 })
    .onClick(() => {
      this.selectedLessonPlan = plan;
      this.showLessonPlanDetail = true;
    })
  }
}