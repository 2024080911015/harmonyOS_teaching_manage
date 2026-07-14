import { RoomInfo, TimeSlot, TimeSlotStatus, ClassroomUserRole } from '../models/ClassroomModels'
import { formatDateDisplay, getStatusColor } from '../utils/ClassroomUtils'
import { BookingDialog } from './BookingDialog'

@CustomDialog
export struct OccupancyDialog {
  controller: CustomDialogController
  @Prop classroom: RoomInfo | null = null
  @Prop userRole: ClassroomUserRole = ClassroomUserRole.STUDENT
  @Prop displayDays: number = 7 // 显示天数，普通用户7天，考务人员14天
  onSlotUpdate?: (classroomId: string, slotId: string, status: TimeSlotStatus, occupant: string, purpose: string) => void
  
  @State selectedDate: string = ''
  @State selectedSlot: TimeSlot | null = null
  
  private dates: string[] = []
  private bookingDialogController: CustomDialogController | null = null
  
  aboutToAppear() {
    if (this.classroom && this.classroom.timeSlots.length > 0) {
      // 获取唯一的日期列表
      const dateSet = new Set<string>()
      this.classroom.timeSlots.forEach(slot => {
        dateSet.add(slot.date)
      })
      this.dates = Array.from(dateSet).slice(0, this.displayDays)
      if (this.dates.length > 0) {
        this.selectedDate = this.dates[0]
      }
    }
  }
  
  // 获取指定日期的时间段
  getTimeSlotsForDate(date: string): TimeSlot[] {
    if (!this.classroom) return []
    return this.classroom.timeSlots.filter(slot => slot.date === date)
  }
  
  // 处理时间段点击
  handleSlotClick(slot: TimeSlot) {
    this.selectedSlot = slot
    if (slot.status === TimeSlotStatus.AVAILABLE) {
      // 空闲时段，弹出借用确认对话框
      this.showBookingConfirmation(slot)
    } else {
      // 显示占用详情
      this.showSlotDetail(slot)
    }
  }
  
  // 显示借用确认对话框
  showBookingConfirmation(slot: TimeSlot) {
    this.selectedSlot = slot
    
    // 创建并打开BookingDialog
    this.bookingDialogController = new CustomDialogController({
      builder: BookingDialog({
        classroom: this.classroom,
        timeSlot: slot,
        userRole: this.userRole,
        onConfirm: (applicantName: string, purpose: string) => {
          // 确认后更新时间段状态
          this.updateSlotStatus(slot.id, TimeSlotStatus.OCCUPIED, applicantName, purpose)
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    })
    
    this.bookingDialogController.open()
  }
  
  // 更新时间段状态
  updateSlotStatus(slotId: string, status: TimeSlotStatus, occupant: string, purpose: string) {
    if (!this.classroom) return
    
    // 找到对应的时间段并更新状态
    const slotIndex = this.classroom.timeSlots.findIndex(slot => slot.id === slotId)
    if (slotIndex !== -1) {
      // 手动更新时间段属性
      const updatedSlot: TimeSlot = {
        id: this.classroom.timeSlots[slotIndex].id,
        date: this.classroom.timeSlots[slotIndex].date,
        startTime: this.classroom.timeSlots[slotIndex].startTime,
        endTime: this.classroom.timeSlots[slotIndex].endTime,
        status: status,
        occupant: occupant,
        purpose: purpose,
        isExam: status === TimeSlotStatus.LOCKED
      }
      
      this.classroom.timeSlots[slotIndex] = updatedSlot
      
      // 触发UI更新 - 手动创建新的classroom对象
      const updatedRoomInfo: RoomInfo = {
        id: this.classroom.id,
        roomNumber: this.classroom.roomNumber,
        campus: this.classroom.campus,
        capacity: this.classroom.capacity,
        type: this.classroom.type,
        building: this.classroom.building,
        floor: this.classroom.floor,
        hasProjector: this.classroom.hasProjector,
        hasComputer: this.classroom.hasComputer,
        timeSlots: this.classroom.timeSlots
      }
      
      this.classroom = updatedRoomInfo
      
      // 调用回调通知父组件
      if (this.onSlotUpdate) {
        this.onSlotUpdate(this.classroom.id, slotId, status, occupant, purpose)
      }
    }
  }
  
  // 显示时间段详情
  showSlotDetail(slot: TimeSlot) {
    let message = `时间段：${slot.startTime} - ${slot.endTime}\n`
    message += `状态：${slot.status}\n`
    if (slot.occupant) {
      message += `${slot.isExam ? '锁定人' : '使用人'}：${slot.occupant}\n`
    }
    if (slot.purpose) {
      message += `用途：${slot.purpose}`
    }
    
    AlertDialog.show({
      title: '时段详情',
      message: message,
      confirm: {
        value: '确定',
        action: () => {}
      }
    })
  }
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Text('教室占用情况')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        
        Blank()
        
        Button('关闭')
          .fontSize(14)
          .backgroundColor('#f5f5f5')
          .fontColor('#666666')
          .onClick(() => {
            this.controller.close()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 15, bottom: 15 })
      .backgroundColor('#ffffff')
      
      Divider().color('#e8e8e8')
      
      // 教室信息
      if (this.classroom) {
        Row() {
          Text(`${this.classroom.roomNumber} - ${this.classroom.building}`)
            .fontSize(16)
            .fontColor('#666666')
          
          Blank()
          
          Text(`显示未来${this.displayDays}天`)
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .backgroundColor('#fafafa')
      }
      
      // 日期选择器
      Scroll() {
        Row() {
          ForEach(this.dates, (date: string) => {
            Column() {
              Text(formatDateDisplay(date))
                .fontSize(14)
                .fontColor(this.selectedDate === date ? '#1890ff' : '#666666')
                .fontWeight(this.selectedDate === date ? FontWeight.Bold : FontWeight.Normal)
            }
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(this.selectedDate === date ? '#e6f7ff' : '#ffffff')
            .borderRadius(4)
            .onClick(() => {
              this.selectedDate = date
            })
          })
        }
        .padding({ left: 10, right: 10 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(50)
      .backgroundColor('#ffffff')
      
      Divider().color('#e8e8e8')
      
      // 时间段列表
      List() {
        ForEach(this.getTimeSlotsForDate(this.selectedDate), (slot: TimeSlot) => {
          ListItem() {
            this.TimeSlotItem(slot)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      
      // 图例说明
      Row() {
        this.LegendItem('空闲', '#52c41a')
        this.LegendItem('已占用', '#ff4d4f')
        this.LegendItem('已锁定', '#faad14')
        this.LegendItem('已预约', '#1890ff')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .backgroundColor('#fafafa')
    }
    .width('90%')
    .height('80%')
    .backgroundColor('#ffffff')
    .borderRadius(12)
    .shadow({ radius: 20, color: '#0000001a', offsetX: 0, offsetY: -2 })
  }
  
  @Builder
  TimeSlotItem(slot: TimeSlot) {
    Row() {
      // 时间显示
      Column() {
        Text(`${slot.startTime} - ${slot.endTime}`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 状态标签
      Row() {
        Text(slot.status)
          .fontSize(14)
          .fontColor('#ffffff')
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(getStatusColor(slot.status))
      .borderRadius(4)
      
      // 操作按钮（仅空闲状态显示）
      if (slot.status === TimeSlotStatus.AVAILABLE) {
        Button('申请')
          .fontSize(14)
          .backgroundColor('#1890ff')
          .margin({ left: 10 })
          .onClick(() => {
            this.handleSlotClick(slot)
          })
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .borderRadius(8)
    .backgroundColor('#ffffff')
    .gesture(
      LongPressGesture()
        .onAction(() => {
          this.showSlotDetail(slot)
        })
    )
  }
  
  @Builder
  LegendItem(text: string, color: string) {
    Row() {
      Circle()
        .width(12)
        .height(12)
        .fill(color)
      
      Text(text)
        .fontSize(12)
        .fontColor('#666666')
        .margin({ left: 4 })
    }
    .margin({ right: 16 })
  }
}
