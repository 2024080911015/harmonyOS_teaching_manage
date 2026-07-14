import { promptAction } from '@kit.ArkUI'
import { AppStateManager } from '../services/AppStateManager'
import { DataService } from '../services/DataService'
import { CourseSchedule, CourseAdjustment, User, AdjustmentStatus, getStatusName, CourseStatus } from '../models/DataModels'

@Entry
@Component
export struct TeacherAdjustmentPage {
  @State appState: AppStateManager = AppStateManager.getInstance()
  @State currentUser: User | null = null
  @State courses: CourseSchedule[] = []
  @State adjustments: CourseAdjustment[] = []
  @State currentTab: number = 0
  @State showApplyDialog: boolean = false
  @State selectedCourse: CourseSchedule | null = null
  @State showSuccessDialog: boolean = false
  @State successMessage: string = ''  // 成功提示信息
  
  // 申请表单
  @State newSchedule: string = ''
  @State newClassroom: string = ''
  @State reason: string = ''
  @State adjustHours: string = '2'  // 调课学时，默认为2
  @State errorMessage: string = ''

  aboutToAppear(): void {
    this.currentUser = this.appState.getCurrentUser() as User
    
    if (this.currentUser) {
      this.courses = DataService.getInstance().getTeacherCourses(this.currentUser.id)
      this.adjustments = DataService.getInstance().getTeacherAdjustments(this.currentUser.id)
    }
  }

  build() {
    Column() {
      // Tab切换
      Row() {
        Text('我的课程')
          .fontSize(16)
          .fontColor(this.currentTab === 0 ? '#1a73e8' : '#666666')
          .fontWeight(this.currentTab === 0 ? FontWeight.Medium : FontWeight.Normal)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .onClick(() => { this.currentTab = 0 })
        
        Text('我的申请')
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
      .border({ width: { bottom: 1 }, color: '#e0e0e0' })
      
      // 内容区域
      if (this.currentTab === 0) {
        this.CourseList()
      } else {
        this.AdjustmentList()
      }
      
      // 申请对话框
      if (this.showApplyDialog) {
        this.ApplyDialog()
      }
      
      // 成功提示
      if (this.showSuccessDialog) {
        this.SuccessDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
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
          .backgroundColor('#e3f2fd')
          .borderRadius(4)
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      // 课程状态
      Row() {
        Text(`状态：${course.courseStatus}`)
          .fontSize(14)
          .fontColor(this.getCourseStatusColor(course.courseStatus))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 4 })
      
      // 教师信息
      Row() {
        Text(`教师：${course.teacherName}`)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 4 })
      
      // 上课时间
      Row() {
        Text(`时间：${course.schedule}`)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 4 })
      
      // 周数范围
      if (course.weekRange) {
        Row() {
          Text(`周数：第${course.weekRange.startWeek}-${course.weekRange.endWeek}周`)
            .fontSize(14)
            .fontColor('#666666')
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 4 })
      }
      
      // 学时
      Row() {
        Text(`学时：${course.hours}学时`)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 4 })
      
      // 教室
      Row() {
        Text(`教室：${course.classroom}`)
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
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 12 })
    .shadow({ radius: 2, color: '#1a000000', offsetX: 0, offsetY: 1 })
  }
  
  // 获取课程状态颜色
  getCourseStatusColor(status: CourseStatus): string {
    switch (status) {
      case CourseStatus.NORMAL:
        return '#4caf50'
      case CourseStatus.ADJUSTED:
        return '#ff9800'
      case CourseStatus.SUSPENDED:
        return '#f44336'
      case CourseStatus.MAKEUP:
        return '#2196f3'
      default:
        return '#666666'
    }
  }

  @Builder
  AdjustmentList() {
    Column() {
      Text(`共 ${this.adjustments.length} 条申请`)
        .fontSize(14)
        .fontColor('#666666')
        .width('90%')
        .margin({ top: 16, bottom: 12 })
      
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
          .fontColor(Color.White)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.getStatusColor(adjustment.status))
          .borderRadius(4)
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      Row() {
        Text(`原时间：${adjustment.originalSchedule}`)
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ bottom: 4 })
      
      Row() {
        Text(`新时间：${adjustment.newSchedule}`)
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ bottom: 4 })
      
      Row() {
        Text(`原教室：${adjustment.originalClassroom}`)
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ bottom: 4 })
      
      Row() {
        Text(`新教室：${adjustment.newClassroom}`)
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ bottom: 4 })
      
      Row() {
        Text(`调课学时：${adjustment.hours}学时`)
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ bottom: 4 })
      
      Row() {
        Text(`原因：${adjustment.reason}`)
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ bottom: 4 })
      
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
      
      Row() {
        Text(`申请时间：${adjustment.createTime}`)
          .fontSize(12)
          .fontColor('#999999')
          .layoutWeight(1)
        
        // 取消申请按钮
        if (adjustment.status === AdjustmentStatus.PENDING_ACADEMIC || 
            adjustment.status === AdjustmentStatus.PENDING_COLLEGE) {
          Button('取消申请')
            .fontSize(12)
            .height(28)
            .backgroundColor('#f44336')
            .fontColor(Color.White)
            .onClick(() => {
              this.handleCancelAdjustment(adjustment.id, false)
            })
        } else if (adjustment.status === AdjustmentStatus.APPROVED || 
                   adjustment.status === AdjustmentStatus.AUTO_APPROVED) {
          Button('申请取消')
            .fontSize(12)
            .height(28)
            .backgroundColor('#ff9800')
            .fontColor(Color.White)
            .onClick(() => {
              this.handleCancelAdjustment(adjustment.id, true)
            })
        }
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 12 })
    .shadow({ radius: 2, color: '#1a000000', offsetX: 0, offsetY: 1 })
  }
  
  // 处理取消调课申请
  handleCancelAdjustment(adjustmentId: string, needApproval: boolean): void {
    const dataService = DataService.getInstance()
    
    if (needApproval) {
      // 已审核通过，需要教务处审批才能取消
      const success = dataService.requestCancelAdjustment(adjustmentId)
      if (success) {
        promptAction.showToast({
          message: '已提交取消申请，等待教务处审批',
          duration: 2000
        })
        // 刷新数据
        if (this.currentUser) {
          this.adjustments = dataService.getTeacherAdjustments(this.currentUser.id)
        }
      } else {
        promptAction.showToast({
          message: '提交取消申请失败',
          duration: 2000
        })
      }
    } else {
      // 未审核，可以直接取消
      const success = dataService.cancelAdjustment(adjustmentId)
      if (success) {
        promptAction.showToast({
          message: '已取消申请',
          duration: 2000
        })
        // 刷新数据
        if (this.currentUser) {
          this.adjustments = dataService.getTeacherAdjustments(this.currentUser.id)
        }
      } else {
        promptAction.showToast({
          message: '取消申请失败',
          duration: 2000
        })
      }
    }
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
          // 课程信息
          Column() {
            Text(`课程：${this.selectedCourse.name}`)
              .fontSize(16)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 8 })
            
            Text(`原时间：${this.selectedCourse.schedule}`)
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
              .margin({ bottom: 8 })
            
            Text(`原教室：${this.selectedCourse.classroom}`)
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#f5f5f5')
          .borderRadius(8)
          .margin({ bottom: 16 })
          
          // 新时间
          Column() {
            Text('新上课时间')
              .fontSize(14)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 8 })
            
            TextInput({ placeholder: '请输入新的上课时间', text: this.newSchedule })
              .fontSize(14)
              .width('100%')
              .height(40)
              .backgroundColor(Color.White)
              .border({ width: 1, color: '#e0e0e0' })
              .borderRadius(4)
              .onChange((value: string) => {
                this.newSchedule = value
              })
          }
          .width('100%')
          .margin({ bottom: 16 })
          
          // 新教室
          Column() {
            Text('新教室')
              .fontSize(14)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 8 })
            
            TextInput({ placeholder: '请输入新的教室', text: this.newClassroom })
              .fontSize(14)
              .width('100%')
              .height(40)
              .backgroundColor(Color.White)
              .border({ width: 1, color: '#e0e0e0' })
              .borderRadius(4)
              .onChange((value: string) => {
                this.newClassroom = value
              })
          }
          .width('100%')
          .margin({ bottom: 16 })
          
          // 调课学时
          Column() {
            Text('调课学时')
              .fontSize(14)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 8 })
            
            TextInput({ text: this.adjustHours })
              .fontSize(14)
              .width('100%')
              .height(40)
              .type(InputType.Number)
              .backgroundColor(Color.White)
              .border({ width: 1, color: '#e0e0e0' })
              .borderRadius(4)
              .onChange((value: string) => {
                this.adjustHours = value
              })
          }
          .width('100%')
          .margin({ bottom: 16 })
          
          // 调课原因
          Column() {
            Text('调课原因')
              .fontSize(14)
              .fontColor('#333333')
              .width('100%')
              .margin({ bottom: 8 })
            
            TextArea({ placeholder: '请输入调课原因', text: this.reason })
              .fontSize(14)
              .width('100%')
              .height(80)
              .backgroundColor(Color.White)
              .border({ width: 1, color: '#e0e0e0' })
              .borderRadius(4)
              .onChange((value: string) => {
                this.reason = value
              })
          }
          .width('100%')
          .margin({ bottom: 20 })
        }
        
        // 按钮
        Row() {
          Button('取消')
            .fontSize(16)
            .width('45%')
            .height(40)
            .backgroundColor('#e0e0e0')
            .fontColor('#666666')
            .onClick(() => {
              this.showApplyDialog = false
              this.resetForm()
            })
          
          Button('提交')
            .fontSize(16)
            .width('45%')
            .height(40)
            .backgroundColor('#1a73e8')
            .fontColor(Color.White)
            .onClick(() => {
              this.submitAdjustment()
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('85%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({ radius: 10, color: '#1a000000', offsetX: 0, offsetY: 5 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // 点击背景关闭对话框
      this.showApplyDialog = false
      this.resetForm()
    })
  }

  @Builder
  SuccessDialog() {
    Column() {
      Column() {
        Text('✓')
          .fontSize(48)
          .fontColor('#4caf50')
          .margin({ bottom: 16 })
        
        Text('提交成功')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ bottom: 8 })
        
        Text(this.successMessage)
          .fontSize(14)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 20 })
        
        Button('确定')
          .fontSize(16)
          .width('80%')
          .height(40)
          .backgroundColor('#1a73e8')
          .fontColor(Color.White)
          .onClick(() => {
            this.showSuccessDialog = false
          })
      }
      .width('70%')
      .padding(24)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({ radius: 10, color: '#1a000000', offsetX: 0, offsetY: 5 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .justifyContent(FlexAlign.Center)
  }

  // 提交调课申请
  private submitAdjustment(): void {
    // 验证表单
    if (this.newSchedule === '') {
      this.errorMessage = '请输入新的上课时间'
      return
    }
    if (this.newClassroom === '') {
      this.errorMessage = '请输入新的教室'
      return
    }
    if (this.reason === '') {
      this.errorMessage = '请输入调课原因'
      return
    }
    
    if (!this.selectedCourse || !this.currentUser) {
      return
    }
    
    // 解析调课学时
    const hours = parseInt(this.adjustHours) || 0
    if (hours <= 0) {
      this.errorMessage = '请输入有效的调课学时'
      return
    }
    
    // 提交申请
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
    
    // 刷新列表
    this.adjustments = DataService.getInstance().getTeacherAdjustments(this.currentUser.id)
    
    // 根据学时判断是否自动通过，设置提示信息
    const isAutoApproved = hours < 8
    this.successMessage = isAutoApproved ? '申请成功！学时小于8，已自动通过审批' : '申请成功！请等待审批'
    
    // 关闭对话框，显示成功提示
    this.showApplyDialog = false
    this.showSuccessDialog = true
    this.resetForm()
  }

  // 重置表单
  private resetForm(): void {
    this.selectedCourse = null
    this.newSchedule = ''
    this.newClassroom = ''
    this.reason = ''
    this.adjustHours = '2'  // 重置为默认值
    this.errorMessage = ''
    this.successMessage = ''  // 重置成功提示
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
}
