import { router, promptAction } from '@kit.ArkUI'
import { User, UserRole, CourseAdjustment, AdjustmentStatus, getStatusName, BookingStatus } from '../models/DataModels'
import { BookingRequest } from '../models/ClassroomModels'
import { DataService } from '../services/DataService'

@Entry
@Component
struct ApprovalPage {
  @State currentUser: User | null = null
  @State pendingAdjustments: CourseAdjustment[] = []
  @State pendingBookings: BookingRequest[] = []  // 待审批的教室预约
  @State currentTab: number = 0
  @State showApprovalDialog: boolean = false
  @State selectedAdjustment: CourseAdjustment | null = null
  @State selectedBooking: BookingRequest | null = null  // 选中的教室预约
  @State approvalComment: string = ''
  @State isApprove: boolean = true

  aboutToAppear(): void {
    this.currentUser = DataService.getInstance().getCurrentUser()
    
    // 权限校验：只有教务处和学院领导才能访问
    if (!this.currentUser || 
        (this.currentUser.role !== UserRole.ACADEMIC_AFFAIRS && 
         this.currentUser.role !== UserRole.COLLEGE_LEADER)) {
      promptAction.showToast({ message: '无权限访问此页面' });
      router.back();
      return;
    }
    
    this.loadPendingAdjustments()
    this.loadPendingBookings()
  }
  
  private loadPendingAdjustments(): void {
    if (!this.currentUser) return
    if (this.currentUser.role === UserRole.ACADEMIC_AFFAIRS) {
      this.pendingAdjustments = DataService.getInstance().getAcademicAffairsPendingAdjustments()
    } else if (this.currentUser.role === UserRole.COLLEGE_LEADER) {
      this.pendingAdjustments = DataService.getInstance().getCollegeLeaderPendingAdjustments()
    }
  }
  
  // 加载待审批的教室预约
  private loadPendingBookings(): void {
    if (!this.currentUser) return
    if (this.currentUser.role === UserRole.ACADEMIC_AFFAIRS) {
      this.pendingBookings = DataService.getInstance().getAcademicAffairsPendingBookings()
    } else if (this.currentUser.role === UserRole.COLLEGE_LEADER) {
      this.pendingBookings = DataService.getInstance().getCollegeLeaderPendingBookings()
    }
  }

  build() {
    Column() {
      this.NavigationBar()
      this.TabBar()
      if (this.currentTab === 0) {
        this.PendingList()
      } else if (this.currentTab === 1) {
        this.BookingApprovalList()
      } else if (this.currentTab === 2) {
        this.ProcessedList()
      } else {
        this.StatsView()
      }
      if (this.showApprovalDialog) {
        this.ApprovalDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  @Builder
  NavigationBar() {
    Row() {
      Text('←').fontSize(24).fontColor('#1a73e8')
        .onClick(() => {
          DataService.getInstance().logout()
          router.back()
        })
      Text(this.getPageTitle()).fontSize(20).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.Center)
      Text(this.currentUser?.name || '').fontSize(14).fontColor('#666666').width(60)
    }
    .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White)
  }

  @Builder
  TabBar() {
    Row() {
      Text('调课审批').fontSize(15).fontColor(this.currentTab === 0 ? '#1a73e8' : '#666666')
        .fontWeight(this.currentTab === 0 ? FontWeight.Medium : FontWeight.Normal)
        .layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 12, bottom: 12 })
        .onClick(() => { this.currentTab = 0 })
      Text('教室审批').fontSize(15).fontColor(this.currentTab === 1 ? '#1a73e8' : '#666666')
        .fontWeight(this.currentTab === 1 ? FontWeight.Medium : FontWeight.Normal)
        .layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 12, bottom: 12 })
        .onClick(() => { this.currentTab = 1 })
      Text('已处理').fontSize(15).fontColor(this.currentTab === 2 ? '#1a73e8' : '#666666')
        .fontWeight(this.currentTab === 2 ? FontWeight.Medium : FontWeight.Normal)
        .layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 12, bottom: 12 })
        .onClick(() => { this.currentTab = 2 })
      Text('统计').fontSize(15).fontColor(this.currentTab === 3 ? '#1a73e8' : '#666666')
        .fontWeight(this.currentTab === 3 ? FontWeight.Medium : FontWeight.Normal)
        .layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 12, bottom: 12 })
        .onClick(() => { this.currentTab = 3 })
    }
    .width('100%').backgroundColor(Color.White).border({ width: { bottom: 1 }, color: '#f0f0f0' })
  }

  @Builder
  PendingList() {
    Column() {
      Text(`待处理：${this.pendingAdjustments.length} 条申请`).fontSize(14).fontColor('#666666')
        .width('90%').margin({ top: 16, bottom: 12 })
      if (this.pendingAdjustments.length === 0) {
        Column() {
          Text('暂无待审批申请').fontSize(16).fontColor('#999999')
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.pendingAdjustments, (adjustment: CourseAdjustment) => {
            ListItem() {
              this.AdjustmentCard(adjustment, true)
            }
          }, (adjustment: CourseAdjustment) => adjustment.id)
        }.width('90%').layoutWeight(1)
      }
    }.width('100%').layoutWeight(1)
  }

  @Builder
  BookingApprovalList() {
    Column() {
      if (this.pendingBookings.length === 0) {
        Column() {
          Text('暂无待审批的教室预约')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 100 })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        List() {
          ForEach(this.pendingBookings, (booking: BookingRequest) => {
            ListItem() {
              this.BookingApprovalCard(booking)
            }
          }, (booking: BookingRequest) => booking.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 16 })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }
  
  @Builder
  BookingApprovalCard(booking: BookingRequest) {
    Column() {
      Row() {
        Text(booking.classroomName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .layoutWeight(1)
        
        Text(this.getBookingStatusName(booking.status))
          .fontSize(12)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.getBookingStatusColor(booking.status))
          .borderRadius(4)
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      Row() {
        Text(`申请人：${booking.applicant}`)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 4 })
      
      Row() {
        Text(`日期：${booking.date}`)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 4 })
      
      Row() {
        Text(`时间段：${booking.timeSlot}`)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 4 })
      
      Row() {
        Text(`用途：${booking.purpose}`)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      // 审批按钮
      Row() {
        Button('通过')
          .fontSize(14)
          .height(36)
          .backgroundColor('#4caf50')
          .fontColor(Color.White)
          .layoutWeight(1)
          .onClick(() => {
            this.handleBookingApproval(booking.id, true)
          })
        
        Button('拒绝')
          .fontSize(14)
          .height(36)
          .backgroundColor('#f44336')
          .fontColor(Color.White)
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            this.handleBookingApproval(booking.id, false)
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
  
  // 获取预约状态名称
  getBookingStatusName(status: BookingStatus): string {
    switch (status) {
      case BookingStatus.PENDING_ACADEMIC:
        return '待教务处审核'
      case BookingStatus.PENDING_COLLEGE:
        return '待学院审核'
      case BookingStatus.PENDING_CANCEL:
        return '待取消审批'
      default:
        return '未知'
    }
  }
  
  // 获取预约状态颜色
  getBookingStatusColor(status: BookingStatus): string {
    switch (status) {
      case BookingStatus.PENDING_ACADEMIC:
      case BookingStatus.PENDING_COLLEGE:
        return '#ff9800'
      case BookingStatus.PENDING_CANCEL:
        return '#ff5722'
      default:
        return '#666666'
    }
  }
  
  // 处理教室预约审批
  handleBookingApproval(bookingId: string, approve: boolean): void {
    const dataService = DataService.getInstance()
    const booking = this.pendingBookings.find(b => b.id === bookingId)
    
    if (!booking) {
      promptAction.showToast({ message: '预约不存在', duration: 2000 })
      return
    }
    
    if (booking.status === BookingStatus.PENDING_CANCEL) {
      // 取消申请审批
      const success = dataService.approveCancelBooking(
        bookingId,
        this.currentUser?.id || '',
        this.currentUser?.name || '',
        approve
      )
      
      if (success) {
        promptAction.showToast({
          message: approve ? '已同意取消' : '已拒绝取消',
          duration: 2000
        })
        this.loadPendingBookings()
      } else {
        promptAction.showToast({ message: '操作失败', duration: 2000 })
      }
    } else {
      // 教室预约审批
      if (this.currentUser?.role === UserRole.ACADEMIC_AFFAIRS) {
        // 教务处审批
        const success = dataService.approveBookingByAcademicAffairs(
          bookingId,
          approve,
          this.currentUser?.id || '',
          this.currentUser?.name || ''
        )
        
        if (success) {
          promptAction.showToast({
            message: approve ? '审批通过' : '审批拒绝',
            duration: 2000
          })
          this.loadPendingBookings()
        } else {
          promptAction.showToast({ message: '操作失败', duration: 2000 })
        }
      } else if (this.currentUser?.role === UserRole.COLLEGE_LEADER) {
        // 学院领导审批
        const success = dataService.approveBookingByCollegeLeader(
          bookingId,
          approve,
          this.currentUser?.id || '',
          this.currentUser?.name || ''
        )
        
        if (success) {
          promptAction.showToast({
            message: approve ? '审批通过' : '审批拒绝',
            duration: 2000
          })
          this.loadPendingBookings()
        } else {
          promptAction.showToast({ message: '操作失败', duration: 2000 })
        }
      }
    }
  }

  @Builder
  ProcessedList() {
    Column() {
      Text('已处理的审批记录').fontSize(14).fontColor('#666666').width('90%').margin({ top: 16, bottom: 12 })
      Column() {
        Text('此处显示已审批的申请记录').fontSize(14).fontColor('#999999').padding(20)
      }.width('90%').backgroundColor(Color.White).borderRadius(8).margin({ top: 8 })
    }.width('100%').layoutWeight(1)
  }

  @Builder
  StatsView() {
    Column() {
      Column() {
        Text('各系调课量统计').fontSize(18).fontWeight(FontWeight.Bold).margin({ bottom: 16 })
        this.DepartmentStatsCard()
      }.width('90%').padding(20).margin({ top: 16 }).borderRadius(12).backgroundColor(Color.White)

      Column() {
        Text('老师调课补完情况').fontSize(18).fontWeight(FontWeight.Bold).margin({ bottom: 16 })
        this.TeacherStatsCard()
      }.width('90%').padding(20).margin({ top: 16 }).borderRadius(12).backgroundColor(Color.White)
    }.width('100%').layoutWeight(1)
  }

  @Builder
  DepartmentStatsCard() {
    Column() {
      Row() {
        Text('系别').fontSize(14).fontColor('#666666').layoutWeight(1)
        Text('总数').fontSize(14).fontColor('#666666').width(50).textAlign(TextAlign.Center)
        Text('待处理').fontSize(14).fontColor('#666666').width(60).textAlign(TextAlign.Center)
        Text('已通过').fontSize(14).fontColor('#666666').width(60).textAlign(TextAlign.Center)
      }.width('100%').padding({ bottom: 8 }).border({ width: { bottom: 1 }, color: '#f0f0f0' })
      this.StatRow('计算机系', 5, 2, 3)
      this.StatRow('数学系', 3, 1, 2)
      this.StatRow('物理系', 2, 0, 2)
    }.width('100%')
  }

  @Builder
  StatRow(dept: string, total: number, pending: number, approved: number) {
    Row() {
      Text(dept).fontSize(14).fontColor('#333333').layoutWeight(1)
      Text(`${total}`).fontSize(14).fontColor('#333333').width(50).textAlign(TextAlign.Center)
      Text(`${pending}`).fontSize(14).fontColor('#ff9800').width(60).textAlign(TextAlign.Center)
      Text(`${approved}`).fontSize(14).fontColor('#4caf50').width(60).textAlign(TextAlign.Center)
    }.width('100%').padding({ top: 8, bottom: 8 })
  }

  @Builder
  TeacherStatsCard() {
    Column() {
      Row() {
        Text('教师').fontSize(14).fontColor('#666666').layoutWeight(1)
        Text('申请数').fontSize(14).fontColor('#666666').width(60).textAlign(TextAlign.Center)
        Text('已完成').fontSize(14).fontColor('#666666').width(60).textAlign(TextAlign.Center)
        Text('完成率').fontSize(14).fontColor('#666666').width(60).textAlign(TextAlign.Center)
      }.width('100%').padding({ bottom: 8 }).border({ width: { bottom: 1 }, color: '#f0f0f0' })
      this.TeacherRow('王教授', 3, 2, 67)
      this.TeacherRow('李教授', 2, 1, 50)
      this.TeacherRow('赵教授', 1, 1, 100)
    }.width('100%')
  }

  @Builder
  TeacherRow(name: string, total: number, completed: number, rate: number) {
    Row() {
      Text(name).fontSize(14).fontColor('#333333').layoutWeight(1)
      Text(`${total}`).fontSize(14).fontColor('#333333').width(60).textAlign(TextAlign.Center)
      Text(`${completed}`).fontSize(14).fontColor('#333333').width(60).textAlign(TextAlign.Center)
      Text(`${rate}%`).fontSize(14).fontColor(rate >= 80 ? '#4caf50' : '#ff9800').width(60).textAlign(TextAlign.Center)
    }.width('100%').padding({ top: 8, bottom: 8 })
  }

  @Builder
  AdjustmentCard(adjustment: CourseAdjustment, showActions: boolean) {
    Column() {
      Row() {
        Text(adjustment.courseName).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#333333').layoutWeight(1)
        Text(getStatusName(adjustment.status)).fontSize(12).fontColor('#ff9800')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(4).backgroundColor('#fff3e0')
      }.width('100%')
      Row() {
        Text(`申请人：${adjustment.teacherName}`).fontSize(14).fontColor('#666666').layoutWeight(1)
        Text(`${adjustment.department}`).fontSize(12).fontColor('#999999')
      }.width('100%').margin({ top: 8 })
      Column() {
        Row() {
          Text('原安排：').fontSize(13).fontColor('#999999')
          Text(`${adjustment.originalSchedule} @ ${adjustment.originalClassroom}`).fontSize(13).fontColor('#666666')
        }.width('100%')
        Row() {
          Text('新安排：').fontSize(13).fontColor('#999999')
          Text(`${adjustment.newSchedule} @ ${adjustment.newClassroom}`).fontSize(13).fontColor('#1a73e8')
        }.width('100%').margin({ top: 4 })
      }.width('100%').margin({ top: 8 }).padding(12).borderRadius(6).backgroundColor('#f9f9f9')
      Row() {
        Text(`调课原因：${adjustment.reason}`).fontSize(13).fontColor('#666666')
      }.width('100%').margin({ top: 8 })
      Row() {
        Text(`调课学时：${adjustment.hours}`).fontSize(12).fontColor('#999999')
        Text(` | 申请时间：${adjustment.createTime}`).fontSize(12).fontColor('#999999').layoutWeight(1)
      }.width('100%').margin({ top: 8 })
      if (showActions) {
        Row() {
          Button('拒绝').fontSize(14).height(36).layoutWeight(1).backgroundColor('#ffebee').fontColor('#f44336')
            .onClick(() => {
              this.selectedAdjustment = adjustment
              this.isApprove = false
              this.showApprovalDialog = true
            })
          Button('通过').fontSize(14).height(36).layoutWeight(1).margin({ left: 12 })
            .backgroundColor('#1a73e8').fontColor(Color.White)
            .onClick(() => {
              this.selectedAdjustment = adjustment
              this.isApprove = true
              this.showApprovalDialog = true
            })
        }.width('100%').margin({ top: 12 })
      }
    }.width('100%').padding(16).margin({ bottom: 8 }).borderRadius(8).backgroundColor(Color.White)
  }

  @Builder
  ApprovalDialog() {
    Column() {
      Column() {
        Text(this.isApprove ? '审批通过' : '审批拒绝').fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 20 })
        if (this.selectedAdjustment) {
          Text(`课程：${this.selectedAdjustment.courseName}`).fontSize(16).fontColor('#333333').margin({ bottom: 8 })
          Text(`申请人：${this.selectedAdjustment.teacherName}`).fontSize(14).fontColor('#666666').margin({ bottom: 16 })
        }
        Column() {
          Text('审批意见（选填）').fontSize(14).fontColor('#666666').margin({ bottom: 8 })
          TextArea({ placeholder: '请输入审批意见', text: this.approvalComment })
            .width('100%').height(80).onChange((value: string) => { this.approvalComment = value })
        }.width('100%').alignItems(HorizontalAlign.Start).margin({ bottom: 20 })
        Row() {
          Button('取消').width('45%').height(44).backgroundColor('#f5f5f5').fontColor('#666666')
            .onClick(() => {
              this.showApprovalDialog = false
              this.selectedAdjustment = null
              this.approvalComment = ''
            })
          Button('确认').width('45%').height(44)
            .backgroundColor(this.isApprove ? '#4caf50' : '#f44336').fontColor(Color.White)
            .onClick(() => { this.handleApproval() })
        }.width('100%').justifyContent(FlexAlign.SpaceBetween)
      }.width('85%').padding(24).borderRadius(16).backgroundColor(Color.White)
    }.width('100%').height('100%').backgroundColor('rgba(0, 0, 0, 0.5)').justifyContent(FlexAlign.Center)
  }

  private getPageTitle(): string {
    if (!this.currentUser) return '审批管理'
    if (this.currentUser.role === UserRole.ACADEMIC_AFFAIRS) {
      return '教务处审批'
    } else if (this.currentUser.role === UserRole.COLLEGE_LEADER) {
      return `${this.currentUser.college}审批`
    }
    return '审批管理'
  }

  private handleApproval(): void {
    if (!this.selectedAdjustment || !this.currentUser) return
    
    if (this.currentUser.role === UserRole.ACADEMIC_AFFAIRS) {
      DataService.getInstance().approveByAcademicAffairs(
        this.selectedAdjustment.id,
        this.currentUser.id,
        this.currentUser.name,
        this.isApprove,
        this.approvalComment
      )
    } else if (this.currentUser.role === UserRole.COLLEGE_LEADER) {
      DataService.getInstance().approveByCollegeLeader(
        this.selectedAdjustment.id,
        this.currentUser.id,
        this.currentUser.name,
        this.isApprove,
        this.approvalComment
      )
    }
    
    this.loadPendingAdjustments()
    this.showApprovalDialog = false
    this.selectedAdjustment = null
    this.approvalComment = ''
  }
}
