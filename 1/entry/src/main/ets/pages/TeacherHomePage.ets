import { showConfirmDialog, SearchBar, EmptyState, StatusTag } from "../components/CommonComponents";
import { Student, Class, LessonPlan, Teacher, Attachment } from "../models/AppModels";
import { AppStateManager } from "../services/AppStateManager";
import { DataService } from "../services/DataService";
import { router, promptAction } from "@kit.ArkUI";

@Entry
@Component

export struct TeacherHomePage {
  @State students: Student[] = [];
  @State filteredStudents: Student[] = [];
  @State searchText: string = '';
  @State currentClass: Class | null = null;
  @State lessonPlans: LessonPlan[] = [];
  @State showLessonPlanDialog: boolean = false;
  @State showLessonPlanDetail: boolean = false;
  @State selectedLessonPlan: LessonPlan | null = null;
  @State newLessonPlanTitle: string = '';
  @State newLessonPlanContent: string = '';
  @State isEditMode: boolean = false; // 是否为编辑模式

  private appState: AppStateManager = AppStateManager.getInstance();
  private dataService: DataService = DataService.getInstance();

  aboutToAppear(): void {
    this.loadData();
  }

  loadData(): void {
    // 获取当前教师所带班级
    const teacher = this.appState.getCurrentUser() as Teacher;
    if (teacher && teacher.classId) {
      const cls = this.dataService.getClassById(teacher.classId);
      if (cls) {
        this.currentClass = cls;
        this.students = cls.students || [];
        this.filteredStudents = [...this.students];
      }
    }

    // 获取教案
    if (teacher) {
      this.lessonPlans = this.dataService.getLessonPlansByTeacher(teacher.id);
    }
  }

  build() {
    // 教案详情页面（独占整个屏幕）
    if (this.showLessonPlanDetail) {
      Column() {
        this.LessonPlanDetailDialog()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F9FA')
    } else {
      // 正常的主页面内容
      Column() {
        // 顶部标题
        Row() {
          Text('教师端 · 班级管理')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
          Blank()
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

        // 班级信息卡片
        if (this.currentClass) {
          this.ClassInfoCard(this.currentClass)
        }

        // 搜索栏
        SearchBar({
          placeholder: '搜索学生（姓名/学号/专业）',
          searchText: $searchText,
          onSearch: (text: string) => {
            this.filterStudents(text);
          }
        })
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })

        // 学生列表
        Text(`共 ${this.filteredStudents.length} 名学生`)
          .fontSize(13)
          .fontColor('#999999')
          .padding({ left: 16, top: 4, bottom: 4 })
          .width('100%')

        if (this.filteredStudents.length > 0) {
          List() {
            ForEach(this.filteredStudents, (student: Student, index: number) => {
              ListItem() {
                this.StudentItem(student)
              }
            }, (student: Student) => student.id)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16 })
        } else {
          EmptyState({ text: this.searchText ? '未找到匹配的学生' : '暂无学生数据' })
            .layoutWeight(1)
        }
        
        // 教案列表
        Column() {
          Row() {
            Text('我的教案')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
            
            Blank()
            
            Button('上传教案')
              .fontSize(14)
              .height(32)
              .backgroundColor('#007AFF')
              .fontColor(Color.White)
              .borderRadius(8)
              .onClick(() => {
                this.showLessonPlanDialog = true;
              })
          }
          .width('100%')
          .margin({ top: 16, bottom: 8 })
          .padding({ left: 16, right: 16 })
          
          if (this.lessonPlans.length > 0) {
            List() {
              ForEach(this.lessonPlans, (plan: LessonPlan) => {
                ListItem() {
                  this.LessonPlanCard(plan)
                }
              }, (plan: LessonPlan) => plan.id)
            }
            .width('100%')
            .height(200)
            .padding({ left: 16, right: 16 })
          } else {
            Text('暂无教案')
              .fontSize(14)
              .fontColor('#999999')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(16)
          }
        }
        .width('100%')

        // 教案上传对话框
        if (this.showLessonPlanDialog) {
          this.LessonPlanDialog()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F9FA')
    }
  }

  @Builder
  ClassInfoCard(cls: Class) {
    Column() {
      Row() {
        Column() {
          Text(cls.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
          Row() {
            Text(`📚 ${cls.major}`)
              .fontSize(13)
              .fontColor('#666666')
            Text(' | ')
              .fontSize(13)
              .fontColor('#666666')
            Text(`📅 ${cls.grade}`)
              .fontSize(13)
              .fontColor('#666666')
            Text(' | ')
              .fontSize(13)
              .fontColor('#666666')
            Text(`👥 ${cls.studentCount}人`)
              .fontSize(13)
              .fontColor('#666666')
          }
          .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Column() {
          Text('辅导员')
            .fontSize(11)
            .fontColor('#999999')
          Text(cls.headTeacher)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#007AFF')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Center)
        .margin({ right: 16 })

        Column() {
          Text('班长')
            .fontSize(11)
            .fontColor('#999999')
          Text(cls.monitor)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FF9500')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding({ left: 4, right: 4 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 8, bottom: 4 })
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: 2 })
  }

  @Builder
  StudentItem(student: Student) {
    Row() {
      // 头像占位
      Column() {
        Text(student.name.charAt(0))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width(44)
      .height(44)
      .backgroundColor('#007AFF')
      .borderRadius(22)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Row() {
          Text(student.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
          Blank()
          StatusTag({ text: student.position || '学生', type: student.position === '班长' ? 'warning' : 'default' })
        }
        .width('100%')

        Row() {
          Text(`学号: ${student.id}`)
            .fontSize(13)
            .fontColor('#999999')
          Text(' | ')
            .fontSize(13)
            .fontColor('#999999')
          Text(`性别: ${student.gender}`)
            .fontSize(13)
            .fontColor('#999999')
          Text(' | ')
            .fontSize(13)
            .fontColor('#999999')
          Text(`专业: ${student.major}`)
            .fontSize(13)
            .fontColor('#999999')
        }
        .margin({ top: 4 })
        .width('100%')
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(Color.White)
    .borderRadius(10)
    .margin({ bottom: 8 })
    .shadow({ radius: 2, color: 'rgba(0,0,0,0.04)', offsetX: 0, offsetY: 1 })
  }

  @Builder
  LessonPlanDialog() {
    Column() {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick(() => {
          this.showLessonPlanDialog = false;
        })

      // 对话框内容
      Column() {
        Text('上传新教案')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .margin({ bottom: 16 })

        TextInput({ placeholder: '教案标题', text: this.newLessonPlanTitle })
          .width('100%')
          .height(44)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 12 })
          .onChange((value: string) => { this.newLessonPlanTitle = value; })

        TextArea({ placeholder: '教案内容', text: this.newLessonPlanContent })
          .width('100%')
          .height(120)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 12, top: 8 })
          .margin({ top: 12 })
          .onChange((value: string) => { this.newLessonPlanContent = value; })

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .backgroundColor('#F0F0F0')
            .fontColor('#666666')
            .borderRadius(8)
            .onClick(() => {
              this.showLessonPlanDialog = false;
            })

          Button('上传')
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#007AFF')
            .fontColor(Color.White)
            .borderRadius(8)
            .margin({ left: 12 })
            .onClick(() => {
              this.submitLessonPlan();
            })
        }
        .width('100%')
        .margin({ top: 16 })
      }
      .width('85%')
      .backgroundColor(Color.White)
      .borderRadius(16)
      .padding({ left: 20, right: 20, top: 24, bottom: 20 })
      .position({ x: '7.5%', y: '30%' })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  private filterStudents(text: string): void {
    if (!text.trim()) {
      this.filteredStudents = [...this.students];
      return;
    }
    const lowerText = text.toLowerCase();
    this.filteredStudents = this.students.filter(s =>
    s.id.includes(text) ||
      s.name.includes(text) ||
      s.major.includes(text) ||
      s.className.includes(text) ||
      s.position.includes(text)
    );
  }

  private submitLessonPlan(): void {
    if (!this.newLessonPlanTitle.trim() || !this.newLessonPlanContent.trim()) {
      promptAction.showToast({ message: '请填写完整的教案信息' });
      return;
    }

    const teacher = this.appState.getCurrentUser() as Teacher;
    if (!teacher) {
      promptAction.showToast({ message: '请先登录' });
      return;
    }

    if (this.isEditMode && this.selectedLessonPlan) {
      // 编辑模式
      const updatedPlan: LessonPlan = {
        id: this.selectedLessonPlan.id,
        title: this.newLessonPlanTitle.trim(),
        classId: this.selectedLessonPlan.classId,
        courseId: this.selectedLessonPlan.courseId,
        teacherId: this.selectedLessonPlan.teacherId,
        teacherName: this.selectedLessonPlan.teacherName,
        uploadTime: new Date().toLocaleString(),
        content: this.newLessonPlanContent.trim(),
        attachments: this.selectedLessonPlan.attachments,
        description: this.selectedLessonPlan.description
      };
      this.dataService.updateLessonPlan(updatedPlan);
    } else {
      // 新增模式
      const newPlan: LessonPlan = {
        id: `LP${Date.now()}`,
        title: this.newLessonPlanTitle.trim(),
        classId: this.currentClass?.id || '',
        courseId: '',
        teacherId: teacher.id,
        teacherName: teacher.name,
        uploadTime: new Date().toLocaleString(),
        content: this.newLessonPlanContent.trim(),
        attachments: [],
        description: ''
      };
      this.dataService.addLessonPlan(newPlan);
    }

    this.lessonPlans = this.dataService.getLessonPlansByTeacher(teacher.id);
    this.showLessonPlanDialog = false;
    this.newLessonPlanTitle = '';
    this.newLessonPlanContent = '';
    this.isEditMode = false;
    this.selectedLessonPlan = null;
    promptAction.showToast({ message: this.isEditMode ? '教案修改成功！' : '教案上传成功！' });
  }
  
  // 教案卡片
  @Builder
  LessonPlanCard(plan: LessonPlan) {
    Column() {
      Row() {
        Text(plan.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      Text(plan.content.substring(0, 50) + (plan.content.length > 50 ? '...' : ''))
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
        .margin({ bottom: 4 })
      
      Row() {
        Text(`上传时间：${plan.uploadTime}`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .onClick(() => {
      this.selectedLessonPlan = plan;
      this.showLessonPlanDetail = true;
    })
  }
  
  // 教案详情页面
  @Builder
  LessonPlanDetailDialog() {
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
      if (this.selectedLessonPlan) {
        Scroll() {
          Column() {
            Text(this.selectedLessonPlan.title)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 16 })
            
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
              .margin({ top: 16, bottom: 16 })
            
            // 操作按钮
            Row() {
              Button('修改')
                .fontSize(14)
                .height(36)
                .backgroundColor('#fff3e0')
                .fontColor('#ff9800')
                .layoutWeight(1)
                .margin({ right: 8 })
                .onClick(() => {
                  this.newLessonPlanTitle = this.selectedLessonPlan!.title;
                  this.newLessonPlanContent = this.selectedLessonPlan!.content;
                  this.isEditMode = true;
                  this.showLessonPlanDetail = false;
                  this.showLessonPlanDialog = true;
                })
              
              Button('删除')
                .fontSize(14)
                .height(36)
                .backgroundColor('#ffebee')
                .fontColor('#f44336')
                .layoutWeight(1)
                .onClick(() => {
                  showConfirmDialog('确认删除', '确定要删除这个教案吗？', () => {
                    this.deleteLessonPlan(this.selectedLessonPlan!.id);
                    this.showLessonPlanDetail = false;
                    this.selectedLessonPlan = null;
                  });
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
  
  // 删除教案
  private deleteLessonPlan(planId: string): void {
    showConfirmDialog(
      '确认删除',
      '确定要删除这个教案吗？',
      () => {
        this.dataService.deleteLessonPlan(planId);
        this.lessonPlans = this.dataService.getAllLessonPlans().filter(
          (p: LessonPlan) => p.teacherId === (this.appState.getCurrentUser() as Teacher).id
        );
        promptAction.showToast({ message: '教案删除成功！' });
      }
    );
  }
}