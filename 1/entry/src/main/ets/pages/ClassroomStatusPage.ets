import { promptAction } from '@kit.ArkUI'
import { AppStateManager } from '../services/AppStateManager'
import { DataService } from '../services/DataService'
import { User, BookingStatus } from '../models/DataModels'
import { RoomType, CampusType, ClassroomUserRole, BookingRequest } from '../models/ClassroomModels'

// 时间段定义
interface TimeSlot {
  id: string
  name: string
  start: string
  end: string
}

// 教室状态
enum RoomStatus {
  AVAILABLE = 'available',    // 空闲
  OCCUPIED = 'occupied',      // 占用（已排课）
  BOOKED = 'booked',         // 已预约
  PENDING = 'pending'        // 已申请待审批
}

// 教室信息
interface RoomInfo {
  id: string
  name: string
  building: string
  capacity: number
  roomType: RoomType        // 教室类型
  campus: CampusType        // 校区
}

// 单个时间段状态
interface SlotStatus {
  roomId: string
  date: string
  slotId: string
  status: RoomStatus
  courseName?: string
  applicant?: string
}

@Entry
@Component
export struct ClassroomStatusPage {
  @State appState: AppStateManager = AppStateManager.getInstance()
  @State currentUser: User | null = null
  @State currentTab: number = 0  // 当前Tab索引
  @State userBookings: BookingRequest[] = []  // 用户的教室申请记录
  @State selectedDate: string = ''
  @State dates: string[] = []
  @State rooms: RoomInfo[] = []
  @State filteredRooms: RoomInfo[] = []  // 筛选后的教室
  @State slotStatuses: SlotStatus[] = []
  @State showBookingDialog: boolean = false
  @State selectedRoom: RoomInfo | null = null
  @State selectedSlot: TimeSlot | null = null
  
  // 搜索和筛选
  @State searchText: string = ''
  @State selectedRoomType: RoomType | null = null
  @State selectedCampus: CampusType | null = null
  
  // 预约表单
  @State bookingPurpose: string = ''
  @State selectedRole: ClassroomUserRole = ClassroomUserRole.STUDENT
  
  // 时间段定义
  private timeSlots: TimeSlot[] = [
    { id: '1-2', name: '第1-2节', start: '08:00', end: '09:40' },
    { id: '3-4', name: '第3-4节', start: '10:00', end: '11:40' },
    { id: '5-6', name: '第5-6节', start: '14:00', end: '15:40' },
    { id: '7-8', name: '第7-8节', start: '16:00', end: '17:40' },
    { id: '9-10', name: '第9-10节', start: '19:00', end: '20:40' }
  ]

  aboutToAppear(): void {
    this.currentUser = this.appState.getCurrentUser() as User
    this.initDates()
    this.initRooms()
    this.loadStatuses()
    this.loadUserBookings()
  }
  
  // 加载用户的教室申请记录
  loadUserBookings(): void {
    if (this.currentUser) {
      const dataService = DataService.getInstance()
      this.userBookings = dataService.getUserBookingRequests(this.currentUser.id)
    }
  }

  // 初始化日期（当前日期及之后4天）
  initDates(): void {
    const today = new Date()
    this.dates = []
    for (let i = 0; i < 5; i++) {
      const date = new Date(today)
      date.setDate(today.getDate() + i)
      const dateStr = this.formatDate(date)
      this.dates.push(dateStr)
    }
    this.selectedDate = this.dates[0]
  }

  // 格式化日期
  formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  // 初始化教室
  initRooms(): void {
    this.rooms = [
      // 主校区
      { id: 'A101', name: '教学楼A101', building: '教学楼A', capacity: 60, roomType: RoomType.ORDINARY, campus: CampusType.MAIN },
      { id: 'A102', name: '教学楼A102', building: '教学楼A', capacity: 80, roomType: RoomType.ORDINARY, campus: CampusType.MAIN },
      { id: 'A201', name: '教学楼A201', building: '教学楼A', capacity: 120, roomType: RoomType.LECTURE_HALL, campus: CampusType.MAIN },
      { id: 'B101', name: '教学楼B101', building: '教学楼B', capacity: 100, roomType: RoomType.MULTI_FUNCTION, campus: CampusType.MAIN },
      { id: 'B102', name: '教学楼B102', building: '教学楼B', capacity: 120, roomType: RoomType.LECTURE_HALL, campus: CampusType.MAIN },
      { id: 'C101', name: '机房C101', building: '实验楼C', capacity: 50, roomType: RoomType.COMPUTER_ROOM, campus: CampusType.MAIN },
      { id: 'C102', name: '机房C102', building: '实验楼C', capacity: 50, roomType: RoomType.COMPUTER_ROOM, campus: CampusType.MAIN },
      { id: 'D101', name: '实验室D101', building: '实验楼D', capacity: 30, roomType: RoomType.LABORATORY, campus: CampusType.MAIN },
      // 东校区
      { id: 'E101', name: '教学楼E101', building: '教学楼E', capacity: 80, roomType: RoomType.ORDINARY, campus: CampusType.EAST },
      { id: 'E102', name: '教学楼E102', building: '教学楼E', capacity: 100, roomType: RoomType.LECTURE_HALL, campus: CampusType.EAST },
      { id: 'F101', name: '机房F101', building: '实验楼F', capacity: 60, roomType: RoomType.COMPUTER_ROOM, campus: CampusType.EAST },
      // 西校区
      { id: 'G101', name: '教学楼G101', building: '教学楼G', capacity: 90, roomType: RoomType.ORDINARY, campus: CampusType.WEST },
      { id: 'G102', name: '多功能厅G102', building: '教学楼G', capacity: 150, roomType: RoomType.MULTI_FUNCTION, campus: CampusType.WEST },
      // 南校区
      { id: 'H101', name: '教学楼H101', building: '教学楼H', capacity: 70, roomType: RoomType.ORDINARY, campus: CampusType.SOUTH },
      { id: 'H102', name: '实验室H102', building: '实验楼H', capacity: 40, roomType: RoomType.LABORATORY, campus: CampusType.SOUTH }
    ]
    this.applyFilters()
  }
  
  // 应用筛选条件
  applyFilters(): void {
    let result = [...this.rooms]
    
    // 搜索过滤
    if (this.searchText.trim()) {
      const keyword = this.searchText.trim().toLowerCase()
      result = result.filter(room =>
        room.name.toLowerCase().includes(keyword) ||
        room.building.toLowerCase().includes(keyword)
      )
    }
    
    // 教室类型筛选
    if (this.selectedRoomType) {
      result = result.filter(room => room.roomType === this.selectedRoomType)
    }
    
    // 校区筛选
    if (this.selectedCampus) {
      result = result.filter(room => room.campus === this.selectedCampus)
    }
    
    this.filteredRooms = result
  }

  // 加载状态数据
  loadStatuses(): void {
    // 模拟数据
    this.slotStatuses = []
    this.rooms.forEach(room => {
      this.dates.forEach(date => {
        this.timeSlots.forEach(slot => {
          // 随机生成状态
          const rand = Math.random()
          let status = RoomStatus.AVAILABLE
          let courseName: string | undefined = undefined
          let applicant: string | undefined = undefined
          
          if (rand < 0.3) {
            status = RoomStatus.OCCUPIED
            courseName = '课程名称'
          } else if (rand < 0.5) {
            status = RoomStatus.BOOKED
            applicant = '预约人'
          } else if (rand < 0.6) {
            status = RoomStatus.PENDING
            applicant = '申请人'
          }
          
          this.slotStatuses.push({
            roomId: room.id,
            date: date,
            slotId: slot.id,
            status: status,
            courseName: courseName,
            applicant: applicant
          })
        })
      })
    })
  }

  // 获取时间段状态
  getSlotStatus(roomId: string, date: string, slotId: string): SlotStatus {
    const status = this.slotStatuses.find(s => 
      s.roomId === roomId && s.date === date && s.slotId === slotId
    )
    return status || {
      roomId: roomId,
      date: date,
      slotId: slotId,
      status: RoomStatus.AVAILABLE
    }
  }

  build() {
    // 预约页面（独占整个屏幕）
    if (this.showBookingDialog) {
      Column() {
        this.BookingDialog()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')
    } else {
      // 正常的主页面内容
      Column() {
        // 顶部标题
        Row() {
          Text('教室管理')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        .backgroundColor(Color.White)
        
        // Tab切换
        Row() {
          Text('教室状态查询')
            .fontSize(16)
            .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTab === 0 ? '#1a73e8' : '#666666')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .onClick(() => {
              this.currentTab = 0
            })
          
          Text('我申请的')
            .fontSize(16)
            .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTab === 1 ? '#1a73e8' : '#666666')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .onClick(() => {
              this.currentTab = 1
              this.loadUserBookings()  // 切换到"我申请的"Tab时刷新数据
            })
        }
        .width('100%')
        .backgroundColor(Color.White)
        .margin({ bottom: 8 })
        
        // 根据Tab显示不同内容
        if (this.currentTab === 0) {
          // 教室状态查询Tab
          this.ClassroomStatusTab()
        } else {
          // 我申请的Tab
          this.MyBookingsTab()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')
    }
  }
  
  // 教室状态查询Tab
  @Builder
  ClassroomStatusTab() {
    Column() {
      // 搜索栏
      Row() {
        TextInput({ placeholder: '搜索教室名称或楼栋...', text: this.searchText })
          .fontSize(14)
          .height(36)
          .layoutWeight(1)
          .backgroundColor('#f5f5f5')
          .borderRadius(8)
          .onChange((value: string) => {
            this.searchText = value
            this.applyFilters()
          })
        
        Button('重置')
          .fontSize(14)
          .height(36)
          .backgroundColor('#e0e0e0')
          .fontColor('#666666')
          .margin({ left: 8 })
          .onClick(() => {
            this.searchText = ''
            this.selectedRoomType = null
            this.selectedCampus = null
            this.applyFilters()
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(Color.White)
      
      // 筛选条件
      Column() {
        // 教室类型筛选
        Row() {
          Text('教室类型：')
            .fontSize(13)
            .fontColor('#666666')
            .width(70)
          
          Scroll() {
            Row() {
              Text('全部')
                .fontSize(12)
                .fontColor(this.selectedRoomType === null ? '#1a73e8' : '#666666')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.selectedRoomType === null ? '#e8f0fe' : '#f5f5f5')
                .borderRadius(4)
                .margin({ right: 6 })
                .onClick(() => {
                  this.selectedRoomType = null
                  this.applyFilters()
                })
              
              Text('梯形教室')
                .fontSize(12)
                .fontColor(this.selectedRoomType === RoomType.LECTURE_HALL ? '#1a73e8' : '#666666')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.selectedRoomType === RoomType.LECTURE_HALL ? '#e8f0fe' : '#f5f5f5')
                .borderRadius(4)
                .margin({ right: 6 })
                .onClick(() => {
                  this.selectedRoomType = RoomType.LECTURE_HALL
                  this.applyFilters()
                })
              
              Text('多功能')
                .fontSize(12)
                .fontColor(this.selectedRoomType === RoomType.MULTI_FUNCTION ? '#1a73e8' : '#666666')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.selectedRoomType === RoomType.MULTI_FUNCTION ? '#e8f0fe' : '#f5f5f5')
                .borderRadius(4)
                .margin({ right: 6 })
                .onClick(() => {
                  this.selectedRoomType = RoomType.MULTI_FUNCTION
                  this.applyFilters()
                })
              
              Text('机房')
                .fontSize(12)
                .fontColor(this.selectedRoomType === RoomType.COMPUTER_ROOM ? '#1a73e8' : '#666666')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.selectedRoomType === RoomType.COMPUTER_ROOM ? '#e8f0fe' : '#f5f5f5')
                .borderRadius(4)
                .margin({ right: 6 })
                .onClick(() => {
                  this.selectedRoomType = RoomType.COMPUTER_ROOM
                  this.applyFilters()
                })
              
              Text('普通教室')
                .fontSize(12)
                .fontColor(this.selectedRoomType === RoomType.ORDINARY ? '#1a73e8' : '#666666')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.selectedRoomType === RoomType.ORDINARY ? '#e8f0fe' : '#f5f5f5')
                .borderRadius(4)
                .margin({ right: 6 })
                .onClick(() => {
                  this.selectedRoomType = RoomType.ORDINARY
                  this.applyFilters()
                })
              
              Text('实验室')
                .fontSize(12)
                .fontColor(this.selectedRoomType === RoomType.LABORATORY ? '#1a73e8' : '#666666')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.selectedRoomType === RoomType.LABORATORY ? '#e8f0fe' : '#f5f5f5')
                .borderRadius(4)
                .margin({ right: 6 })
                .onClick(() => {
                  this.selectedRoomType = RoomType.LABORATORY
                  this.applyFilters()
                })
            }
            .margin({ right: 16 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Auto)
          .scrollBarWidth(4)
          .scrollBarColor(Color.Transparent)
          .height(32)
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 8 })
        
        // 校区筛选
        Row() {
          Text('校区：')
            .fontSize(13)
            .fontColor('#666666')
            .width(70)
          
          Scroll() {
            Row() {
              Text('全部')
                .fontSize(12)
                .fontColor(this.selectedCampus === null ? '#1a73e8' : '#666666')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.selectedCampus === null ? '#e8f0fe' : '#f5f5f5')
                .borderRadius(4)
                .margin({ right: 6 })
                .onClick(() => {
                  this.selectedCampus = null
                  this.applyFilters()
                })
              
              Text('主校区')
                .fontSize(12)
                .fontColor(this.selectedCampus === CampusType.MAIN ? '#1a73e8' : '#666666')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.selectedCampus === CampusType.MAIN ? '#e8f0fe' : '#f5f5f5')
                .borderRadius(4)
                .margin({ right: 6 })
                .onClick(() => {
                  this.selectedCampus = CampusType.MAIN
                  this.applyFilters()
                })
              
              Text('东校区')
                .fontSize(12)
                .fontColor(this.selectedCampus === CampusType.EAST ? '#1a73e8' : '#666666')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.selectedCampus === CampusType.EAST ? '#e8f0fe' : '#f5f5f5')
                .borderRadius(4)
                .margin({ right: 6 })
                .onClick(() => {
                  this.selectedCampus = CampusType.EAST
                  this.applyFilters()
                })
              
              Text('西校区')
                .fontSize(12)
                .fontColor(this.selectedCampus === CampusType.WEST ? '#1a73e8' : '#666666')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.selectedCampus === CampusType.WEST ? '#e8f0fe' : '#f5f5f5')
                .borderRadius(4)
                .margin({ right: 6 })
                .onClick(() => {
                  this.selectedCampus = CampusType.WEST
                  this.applyFilters()
                })
              
              Text('南校区')
                .fontSize(12)
                .fontColor(this.selectedCampus === CampusType.SOUTH ? '#1a73e8' : '#666666')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(this.selectedCampus === CampusType.SOUTH ? '#e8f0fe' : '#f5f5f5')
                .borderRadius(4)
                .margin({ right: 6 })
                .onClick(() => {
                  this.selectedCampus = CampusType.SOUTH
                  this.applyFilters()
                })
            }
            .margin({ right: 16 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Auto)
          .scrollBarWidth(4)
          .scrollBarColor(Color.Transparent)
          .height(32)
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(Color.White)
      .margin({ top: 1 })
      
      // 日期选择
      Scroll() {
        Row() {
          ForEach(this.dates, (date: string) => {
            Column() {
              Text(this.getDateDisplay(date))
                .fontSize(14)
                .fontColor(this.selectedDate === date ? '#1a73e8' : '#666666')
                .fontWeight(this.selectedDate === date ? FontWeight.Medium : FontWeight.Normal)
            }
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(this.selectedDate === date ? '#e3f2fd' : Color.Transparent)
            .borderRadius(4)
            .onClick(() => {
              this.selectedDate = date
            })
          }, (date: string) => date)
        }
        .margin({ right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Auto)
      .scrollBarWidth(4)
      .scrollBarColor(Color.Transparent)
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(Color.White)
      
      // 教室列表
      if (this.filteredRooms.length === 0) {
        Column() {
          Text('暂无符合条件的教室')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 40 })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        List() {
          ForEach(this.filteredRooms, (room: RoomInfo) => {
            ListItem() {
              this.RoomCard(room)
            }
          }, (room: RoomInfo) => room.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 16 })
      }
      
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
  
  // 我申请的Tab
  @Builder
  MyBookingsTab() {
    Column() {
      if (this.userBookings.length === 0) {
        // 空状态
        Column() {
          Text('暂无申请记录')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 100 })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        // 申请记录列表
        List() {
          ForEach(this.userBookings, (booking: BookingRequest) => {
            ListItem() {
              this.BookingCard(booking)
            }
          }, (booking: BookingRequest) => booking.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
  
  // 申请记录卡片
  @Builder
  BookingCard(booking: BookingRequest) {
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
      .margin({ bottom: 4 })
      
      Row() {
        Text(`申请时间：${booking.createTime}`)
          .fontSize(12)
          .fontColor('#999999')
          .layoutWeight(1)
        
        // 取消申请按钮
        if (booking.status === BookingStatus.PENDING_ACADEMIC || 
            booking.status === BookingStatus.PENDING_COLLEGE) {
          Button('取消申请')
            .fontSize(12)
            .height(28)
            .backgroundColor('#f44336')
            .fontColor(Color.White)
            .onClick(() => {
              this.handleCancelBooking(booking.id, false)
            })
        } else if (booking.status === BookingStatus.APPROVED || 
                   booking.status === BookingStatus.AUTO_APPROVED) {
          Button('申请取消')
            .fontSize(12)
            .height(28)
            .backgroundColor('#ff9800')
            .fontColor(Color.White)
            .onClick(() => {
              this.handleCancelBooking(booking.id, true)
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
  
  // 获取预约状态名称
  getBookingStatusName(status: BookingStatus): string {
    switch (status) {
      case BookingStatus.PENDING_ACADEMIC:
        return '待教务处审核'
      case BookingStatus.PENDING_COLLEGE:
        return '待学院审核'
      case BookingStatus.APPROVED:
        return '已通过'
      case BookingStatus.REJECTED:
        return '已拒绝'
      case BookingStatus.CANCELLED:
        return '已取消'
      case BookingStatus.PENDING_CANCEL:
        return '待取消审批'
      case BookingStatus.AUTO_APPROVED:
        return '自动通过'
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
      case BookingStatus.APPROVED:
      case BookingStatus.AUTO_APPROVED:
        return '#4caf50'
      case BookingStatus.REJECTED:
        return '#f44336'
      case BookingStatus.CANCELLED:
        return '#999999'
      case BookingStatus.PENDING_CANCEL:
        return '#ff5722'
      default:
        return '#666666'
    }
  }
  
  // 处理取消预约申请
  handleCancelBooking(bookingId: string, needApproval: boolean): void {
    const dataService = DataService.getInstance()
    
    if (needApproval) {
      // 已审核通过，需要教务处审批才能取消
      const success = dataService.requestCancelBooking(bookingId)
      if (success) {
        promptAction.showToast({
          message: '已提交取消申请，等待教务处审批',
          duration: 2000
        })
        // 刷新数据
        this.loadUserBookings()
      } else {
        promptAction.showToast({
          message: '提交取消申请失败',
          duration: 2000
        })
      }
    } else {
      // 未审核，可以直接取消
      const success = dataService.cancelBookingRequest(bookingId)
      if (success) {
        promptAction.showToast({
          message: '已取消申请',
          duration: 2000
        })
        // 刷新数据
        this.loadUserBookings()
      } else {
        promptAction.showToast({
          message: '取消申请失败',
          duration: 2000
        })
      }
    }
  }

  // 日期显示
  getDateDisplay(date: string): string {
    const today = this.formatDate(new Date())
    if (date === today) {
      return '今天'
    }
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    if (date === this.formatDate(tomorrow)) {
      return '明天'
    }
    // 显示月-日
    const parts = date.split('-')
    return `${parts[1]}-${parts[2]}`
  }

  @Builder
  RoomCard(room: RoomInfo) {
    Column() {
      // 教室信息
      Row() {
        Column() {
          Text(room.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1a1a1a')
          
          Row() {
            Text(room.building)
              .fontSize(12)
              .fontColor('#999999')
            
            Text(' | ')
              .fontSize(12)
              .fontColor('#999999')
            
            Text(`容量: ${room.capacity}人`)
              .fontSize(12)
              .fontColor('#999999')
            
            Text(' | ')
              .fontSize(12)
              .fontColor('#999999')
            
            Text(room.roomType)
              .fontSize(12)
              .fontColor('#666666')
            
            Text(' | ')
              .fontSize(12)
              .fontColor('#999999')
            
            Text(room.campus)
              .fontSize(12)
              .fontColor('#666666')
          }
          .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      
      // 时间段状态
      Row() {
        ForEach(this.timeSlots, (slot: TimeSlot) => {
          this.StatusTag(room, slot)
        }, (slot: TimeSlot) => slot.id)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding({ left: 8, right: 8, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 12 })
    .shadow({ radius: 2, color: '#1a000000', offsetX: 0, offsetY: 1 })
  }

  @Builder
  StatusTag(room: RoomInfo, slot: TimeSlot) {
    Column() {
      Text(slot.name)
        .fontSize(11)
        .fontColor('#666666')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      
      if (this.getSlotStatus(room.id, this.selectedDate, slot.id).status === RoomStatus.AVAILABLE) {
        // 空闲状态，显示预约按钮
        Button('空闲')
          .fontSize(10)
          .height(22)
          .backgroundColor('#4caf50')
          .fontColor(Color.White)
          .margin({ top: 4 })
          .onClick(() => {
            this.selectedRoom = room
            this.selectedSlot = slot
            this.showBookingDialog = true
          })
      } else if (this.getSlotStatus(room.id, this.selectedDate, slot.id).status === RoomStatus.OCCUPIED) {
        // 占用状态
        Text('占用')
          .fontSize(10)
          .fontColor('#f44336')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('#ffebee')
          .borderRadius(4)
          .margin({ top: 4 })
      } else if (this.getSlotStatus(room.id, this.selectedDate, slot.id).status === RoomStatus.BOOKED) {
        // 已预约
        Text('已预约')
          .fontSize(10)
          .fontColor('#ff9800')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('#fff3e0')
          .borderRadius(4)
          .margin({ top: 4 })
      } else {
        // 待审批
        Text('待审批')
          .fontSize(10)
          .fontColor('#2196f3')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('#e3f2fd')
          .borderRadius(4)
          .margin({ top: 4 })
      }
    }
    .width(60)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  BookingDialog() {
    Column() {
      // 标题栏
      Row() {
        Button('← 返回')
          .fontSize(14)
          .fontColor('#1a73e8')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showBookingDialog = false
            this.bookingPurpose = ''
          })
        
        Blank()
        
        Text('预约教室')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      
      if (this.selectedRoom && this.selectedSlot) {
        // 可滚动区域（教室信息和预约用途）
        Scroll() {
          Column() {
            // 教室信息
            Column() {
              Text(`教室：${this.selectedRoom.name}`)
                .fontSize(16)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 8 })
              
              Text(`日期：${this.selectedDate}`)
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
                .margin({ bottom: 8 })
              
              Text(`时间：${this.selectedSlot.name} (${this.selectedSlot.start}-${this.selectedSlot.end})`)
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .margin({ bottom: 16 })
            
            // 预约用途
            Column() {
              Text('预约用途')
                .fontSize(14)
                .fontColor('#333333')
                .width('100%')
                .margin({ bottom: 8 })
              
              TextArea({ placeholder: '请输入预约用途', text: this.bookingPurpose })
                .fontSize(14)
                .width('100%')
                .height(80)
                .backgroundColor(Color.White)
                .border({ width: 1, color: '#e0e0e0' })
                .borderRadius(4)
                .onChange((value: string) => {
                  this.bookingPurpose = value
                })
            }
            .width('100%')
            .margin({ bottom: 20 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .scrollBarColor('#1a73e8')
        .scrollBarWidth(4)
        .edgeEffect(EdgeEffect.Spring)
        
        // 固定在底部的按钮
        Row() {
          Button('取消')
            .fontSize(16)
            .width('45%')
            .height(40)
            .backgroundColor('#e0e0e0')
            .fontColor('#666666')
            .onClick(() => {
              this.showBookingDialog = false
              this.bookingPurpose = ''
            })
          
          Button('提交')
            .fontSize(16)
            .width('45%')
            .height(40)
            .backgroundColor('#1a73e8')
            .fontColor(Color.White)
            .onClick(() => {
              this.submitBooking()
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(Color.White)
        .justifyContent(FlexAlign.SpaceBetween)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  // 提交预约
  private submitBooking(): void {
    if (this.bookingPurpose === '') {
      promptAction.showToast({ message: '请输入预约用途' })
      return
    }
    
    if (!this.currentUser) {
      promptAction.showToast({ message: '请先登录' })
      return
    }
    
    // 提交预约申请
    if (this.selectedRoom && this.selectedSlot) {
      DataService.getInstance().submitBookingRequest(
        this.selectedRoom.id,
        this.selectedRoom.name,
        this.selectedDate,
        this.selectedSlot.start,
        this.selectedSlot.end,
        this.bookingPurpose,
        this.currentUser.id,
        this.currentUser.name,
        this.selectedRole
      )
      
      promptAction.showToast({ message: '预约申请已提交' })
      this.showBookingDialog = false
      this.bookingPurpose = ''
      
      // 重新加载状态和用户申请列表
      this.loadStatuses()
      this.loadUserBookings()
    }
  }
}
