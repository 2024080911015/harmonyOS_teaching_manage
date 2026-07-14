import { router, promptAction } from '@kit.ArkUI'
import { CourseSchedule, CourseAdjustment, User, getApprovalType, ApprovalType, getStatusName, AdjustmentStatus, UserRole } from '../models/DataModels'
import { DataService } from '../services/DataService'

@Entry
@Component
struct TeacherPage {
  @State currentUser: User | null = null
  @State courses: CourseSchedule[] = []
  @State adjustments: CourseAdjustment[] = []
  @State currentTab: number = 0
  @State showApplyDialog: boolean = false
  @State selectedCourse: CourseSchedule | null = null
  @State showSuccessDialog: boolean = false
  @State successMessage: string = '申请成功'
  @State errorMessage: string = ''  // 错误提示信息
  
  // 调课申请表单
  @State newSchedule: string = ''
  @State newClassroom: string = ''
  @State adjustHours: string = '4'
  @State reason: string = ''
  
  aboutToAppear(): void {
    this.currentUser = DataService.getInstance().getCurrentUser()
    
    // 权限校验：只有教师才能访问
    if (!this.currentUser || this.currentUser.role !== UserRole.TEACHER) {
      promptAction.showToast({ message: '无权限访问此页面' });
      router.back();
      return;
    }
    
    this.loadData()
  }
  
  // 页面显示时重新加载数据（从其他页面返回时刷新）
  onPageShow(): void {
    this.loadData()
  }
  
  // 加载数据
  private loadData(): void {
    if (this.currentUser) {
      this.courses = DataService.getInstance().getTeacherCourses(this.currentUser.id)
      this.adjustments = DataService.getInstance().getTeacherAdjustments(this.currentUser.id)
    }
  }
  
  build() {
    Column() {
      // 顶部导航栏
      this.NavigationBar()
      
      // Tab切换
      this.TabBar()
      
      // 内容区域
      if (this.currentTab === 0) {
        this.CourseList()
      } else {
        this.AdjustmentList()
      }
      
      // 调课申请对话框
      if (this.showApplyDialog) {
        this.ApplyDialog()
      }
      
      // 成功提示对话框
      if (this.showSuccessDialog) {
        this.SuccessDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
  
  @Builder
  NavigationBar() {
    Row() {
      Text('←')
        .fontSize(24)
        .fontColor('#1a73e8')
        .onClick(() => {
          DataService.getInstance().logout()
          router.back()
        })
      
      Text('我的课程')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      Text(this.currentUser?.name || '老师')
        .fontSize(14)
        .fontColor('#666666')
        .width(60)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }
  
  @Builder
  TabBar() {
    Row() {
      Text('我的课程')
        .fontSize(16)
        .fontColor(this.currentTab === 0 ? '#1a73e8' : '#666666')
        .fontWeight(this.currentTab === 0 ? FontWeight.Medium : FontWeight.Normal)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .padding({ top: 12, bottom: 12 })
        .onClick(() => { this.currentTab = 0 })
      
      Text('调课申请')
        .fontSize(16)
        .fontColor(this.currentTab === 1 ? '#1a73e8' : '#666666')
        .fontWeight(this.currentTab === 1 ? FontWeight.Medium : FontWeight.Normal)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .padding({ top: 12, bottom: 12 })
        .onClick(() => { this.currentTab = 1 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .border({ width: { bottom: 1 }, color: '#f0f0f0' })
  }
  
  @Builder
  CourseList() {
    Column() {
      Text(`共 ${this.courses.length} 门课程`)
        .fontSize(14)
        .fontColor('#666666')
        .width('90%')
        .margin({ top: 16, bottom: 12 })
      
      List() {
        ForEach(this.courses, (course: CourseSchedule) => {
          ListItem() {
            this.CourseCard(course)
          }
        }, (course: CourseSchedule) => course.id)
      }
      .width('90%')
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
  }
  
  @Builder
  CourseCard(course: CourseSchedule) {
    Column() {
      Row() {
        Text(course.name)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
        
        Text(`${course.credit}学分`)
          .fontSize(12)
          .fontColor('#1a73e8')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(4)
          .backgroundColor('#e3f2fd')
      }
      .width('100%')
      
      Row() {
        Text(`时间：${course.schedule}`)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
        
        Text(`教室：${course.classroom}`)
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ top: 8 })
      
      Row() {
        Text(`学时：${course.hours}`)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
        
        Button('申请调课')
          .fontSize(14)
          .height(32)
          .backgroundColor('#ff9800')
          .fontColor(Color.White)
          .onClick(() => {
            this.selectedCourse = course
            this.newSchedule = course.schedule
            this.newClassroom = course.classroom
            this.showApplyDialog = true
          })
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .margin({ bottom: 8 })
    .borderRadius(8)
    .backgroundColor(Color.White)
  }
  
  @Builder
  AdjustmentList() {
    Column() {
      Text(`共 ${this.adjustments.length} 条申请记录`)
        .fontSize(14)
        .fontColor('#666666')
        .width('90%')
        .margin({ top: 16, bottom: 12 })
      
      if (this.adjustments.length === 0) {
        Column() {
          Text('暂无调课申请记录')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 100 })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        List() {
          ForEach(this.adjustments, (adjustment: CourseAdjustment) => {
            ListItem() {
              this.AdjustmentCard(adjustment)
            }
          }, (adjustment: CourseAdjustment) => adjustment.id)
        }
        .width('90%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }
  
  @Builder
  AdjustmentCard(adjustment: CourseAdjustment) {
    Column() {
      Row() {
        Text(adjustment.courseName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
        
        Text(getStatusName(adjustment.status))
          .fontSize(12)
          .fontColor(this.getStatusColor(adjustment.status))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(4)
          .backgroundColor(this.getStatusBgColor(adjustment.status))
      }
      .width('100%')
      
      Row() {
        Text(`原时间：${adjustment.originalSchedule}`)
          .fontSize(13)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ top: 6 })
      
      Row() {
        Text(`新时间：${adjustment.newSchedule}`)
          .fontSize(13)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ top: 4 })
      
      Row() {
        Text(`调课学时：${adjustment.hours}`)
          .fontSize(13)
          .fontColor('#666666')
          .layoutWeight(1)
        
        Text(this.getApprovalTypeText(adjustment.approvalType))
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .margin({ top: 4 })
      
      Row() {
        Text(`申请时间：${adjustment.createTime}`)
          .fontSize(12)
          .fontColor('#999999')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 4 })
      
      // 显示教务处审批意见
      if (adjustment.academicAffairsApproval && adjustment.academicAffairsApproval.approvalComment) {
        Row() {
          Text(`教务处意见：${adjustment.academicAffairsApproval.approvalComment}`)
            .fontSize(12)
            .fontColor('#ff9800')
        }
        .width('100%')
        .margin({ top: 4 })
      }
      
      // 显示学院领导审批意见
      if (adjustment.collegeLeaderApproval && adjustment.collegeLeaderApproval.approvalComment) {
        Row() {
          Text(`学院领导意见：${adjustment.collegeLeaderApproval.approvalComment}`)
            .fontSize(12)
            .fontColor('#ff9800')
        }
        .width('100%')
        .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(14)
    .margin({ bottom: 8 })
    .borderRadius(8)
    .backgroundColor(Color.White)
  }
  
  @Builder
  ApplyDialog() {
    Column() {
      Column() {
        Text('申请调课')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })
        
        // 错误提示区域
        if (this.errorMessage !== '') {
          Row() {
            Text('⚠ ' + this.errorMessage)
              .fontSize(14)
              .fontColor('#f44336')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#ffebee')
          .borderRadius(8)
          .margin({ bottom: 16 })
        }
        
        if (this.selectedCourse) {
          Text(`课程：${this.selectedCourse.name}`)
            .fontSize(16)
            .fontColor('#333333')
            .margin({ bottom: 16 })
          
          // 新上课时间
          Column() {
            Text('新上课时间')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 8 })
            
            TextInput({ placeholder: '例如：周五 1-2节', text: this.newSchedule })
              .width('100%')
              .height(40)
              .onChange((value: string) => {
                this.newSchedule = value
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })
          
          // 新教室
          Column() {
            Text('新教室')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 8 })
            
            TextInput({ placeholder: '例如：A102', text: this.newClassroom })
              .width('100%')
              .height(40)
              .onChange((value: string) => {
                this.newClassroom = value
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })
          
          // 调课学时
          Column() {
            Text('调课学时')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 8 })
            
            TextInput({ text: this.adjustHours })
              .width('100%')
              .height(40)
              .type(InputType.Number)
              .onChange((value: string) => {
                this.adjustHours = value
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 16 })
          
          // 审批提示
          Text(this.getApprovalHint())
            .fontSize(13)
            .fontColor('#ff9800')
            .margin({ bottom: 16 })
          
          // 调课原因
          Column() {
            Text('调课原因')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 8 })
            
            TextArea({ placeholder: '请输入调课原因', text: this.reason })
              .width('100%')
              .height(80)
              .onChange((value: string) => {
                this.reason = value
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 20 })
          
          // 按钮
          Row() {
            Button('取消')
              .width('45%')
              .height(44)
              .backgroundColor('#f5f5f5')
              .fontColor('#666666')
              .onClick(() => {
                this.showApplyDialog = false
                this.selectedCourse = null
                this.resetForm()
              })
            
            Button('提交申请')
              .width('45%')
              .height(44)
              .backgroundColor('#1a73e8')
              .fontColor(Color.White)
              .onClick(() => {
                this.submitAdjustment()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
      }
      .width('85%')
      .padding(24)
      .borderRadius(16)
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // 点击背景不关闭
    })
  }
  
  private getStatusColor(status: AdjustmentStatus): string {
    switch (status) {
      case AdjustmentStatus.PENDING_ACADEMIC:
      case AdjustmentStatus.PENDING_COLLEGE:
        return '#ff9800'
      case AdjustmentStatus.APPROVED:
      case AdjustmentStatus.AUTO_APPROVED:
        return '#4caf50'
      case AdjustmentStatus.REJECTED:
        return '#f44336'
      default:
        return '#666666'
    }
  }
  
  private getStatusBgColor(status: AdjustmentStatus): string {
    switch (status) {
      case AdjustmentStatus.PENDING_ACADEMIC:
      case AdjustmentStatus.PENDING_COLLEGE:
        return '#fff3e0'
      case AdjustmentStatus.APPROVED:
      case AdjustmentStatus.AUTO_APPROVED:
        return '#e8f5e9'
      case AdjustmentStatus.REJECTED:
        return '#ffebee'
      default:
        return '#f5f5f5'
    }
  }
  
  private getApprovalTypeText(type: ApprovalType): string {
    switch (type) {
      case ApprovalType.AUTO:
        return '自动通过'
      case ApprovalType.ACADEMIC_AFFAIRS:
        return '教务处审批'
      case ApprovalType.COLLEGE_LEADER:
        return '学院领导审批'
      default:
        return ''
    }
  }
  
  private getApprovalHint(): string {
    const hours = parseInt(this.adjustHours) || 0
    const type = getApprovalType(hours)
    switch (type) {
      case ApprovalType.AUTO:
        return '💡 学时小于8，将自动通过审批'
      case ApprovalType.ACADEMIC_AFFAIRS:
        return '📋 学时8-12，需教务处审批'
      case ApprovalType.COLLEGE_LEADER:
        return '👔 学时超过12，需学院领导审批'
      default:
        return ''
    }
  }
  
  private resetForm(): void {
    this.newSchedule = ''
    this.newClassroom = ''
    this.adjustHours = '4'
    this.reason = ''
    this.errorMessage = ''
  }
  
  private submitAdjustment(): void {
    // 清除之前的错误提示
    this.errorMessage = ''
    
    // 表单验证
    if (!this.selectedCourse) {
      this.errorMessage = '请选择课程'
      return
    }
    
    if (!this.newSchedule || this.newSchedule.trim() === '') {
      this.errorMessage = '请填写新上课时间'
      return
    }
    
    if (!this.newClassroom || this.newClassroom.trim() === '') {
      this.errorMessage = '请填写新教室'
      return
    }
    
    if (!this.reason || this.reason.trim() === '') {
      this.errorMessage = '请填写调课原因'
      return
    }
    
    const hours = parseInt(this.adjustHours) || 0
    
    // 判断是否自动通过
    const isAutoApproved = hours < 8
    this.successMessage = isAutoApproved ? '申请成功！学时小于8，已自动通过审批' : '申请成功！请等待审批'
    
    if (this.selectedCourse && this.currentUser) {
      DataService.getInstance().submitAdjustment(
        this.selectedCourse.id,
        this.selectedCourse.name,
        this.currentUser.id,
        this.currentUser.name,
        this.selectedCourse.department,
        this.selectedCourse.college,
        this.selectedCourse.schedule,
        this.newSchedule,
        this.selectedCourse.classroom,
        this.newClassroom,
        hours,
        this.reason
      )
    }
    
    // 刷新列表
    if (this.currentUser) {
      this.adjustments = DataService.getInstance().getTeacherAdjustments(this.currentUser.id)
    }
    
    this.showApplyDialog = false
    this.selectedCourse = null
    this.resetForm()
    
    // 显示成功提示
    this.showSuccessDialog = true
  }
  
  @Builder
  SuccessDialog() {
    Column() {
      Column() {
        Text('✓')
          .fontSize(48)
          .fontColor('#4caf50')
          .margin({ bottom: 16 })
        
        Text(this.successMessage)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 24 })
        
        Button('确定')
          .width('60%')
          .height(44)
          .backgroundColor('#1a73e8')
          .fontColor(Color.White)
          .onClick(() => {
            this.showSuccessDialog = false
            this.currentTab = 1 // 切换到调课申请列表
          })
      }
      .width('80%')
      .padding(32)
      .borderRadius(16)
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .justifyContent(FlexAlign.Center)
  }
}
