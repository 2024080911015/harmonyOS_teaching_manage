import { RoomInfo, TimeSlot, TimeSlotStatus, RoomType, CampusType } from '../models/ClassroomModels'

// 生成未来N天的日期数组
export function generateFutureDates(days: number): string[] {
  const dates: string[] = []
  const today = new Date()
  
  for (let i = 0; i < days; i++) {
    const date = new Date(today)
    date.setDate(today.getDate() + i)
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    dates.push(`${year}-${month}-${day}`)
  }
  
  return dates
}

// 时间范围接口
interface TimeRange {
  start: string
  end: string
}

// 教室数据接口
interface RoomDataItem {
  number: string
  campus: CampusType
  capacity: number
  type: RoomType
  building: string
  floor: number
}

// 生成时间段（每天8:00-22:00，每2小时一个时段）
export function generateTimeSlotsForDate(date: string): TimeSlot[] {
  const slots: TimeSlot[] = []
  const timeRanges: TimeRange[] = [
    { start: '08:00', end: '10:00' },
    { start: '10:00', end: '12:00' },
    { start: '14:00', end: '16:00' },
    { start: '16:00', end: '18:00' },
    { start: '19:00', end: '21:00' }
  ]
  
  timeRanges.forEach((range, index) => {
    const random = Math.random()
    let status = TimeSlotStatus.AVAILABLE
    let occupant: string | undefined = undefined
    let purpose: string | undefined = undefined
    let isExam = false
    
    if (random < 0.3) {
      status = TimeSlotStatus.OCCUPIED
      occupant = '张老师'
      purpose = '正常教学'
    } else if (random < 0.4) {
      status = TimeSlotStatus.LOCKED
      occupant = '教务处'
      purpose = '期末考试'
      isExam = true
    } else if (random < 0.5) {
      status = TimeSlotStatus.BOOKED
      occupant = '李同学'
      purpose = '社团活动'
    }
    
    slots.push({
      id: `${date}-${index}`,
      date: date,
      startTime: range.start,
      endTime: range.end,
      status: status,
      occupant: occupant,
      purpose: purpose,
      isExam: isExam
    })
  })
  
  return slots
}

// 生成模拟教室数据
export function generateMockRoomInfos(): RoomInfo[] {
  const classrooms: RoomInfo[] = []
  const dates = generateFutureDates(14) // 生成未来14天
  
  const roomData: RoomDataItem[] = [
    { number: 'A101', campus: CampusType.MAIN, capacity: 120, type: RoomType.LECTURE_HALL, building: '教学楼A', floor: 1 },
    { number: 'A201', campus: CampusType.MAIN, capacity: 80, type: RoomType.MULTI_FUNCTION, building: '教学楼A', floor: 2 },
    { number: 'B301', campus: CampusType.EAST, capacity: 60, type: RoomType.COMPUTER_ROOM, building: '信息楼B', floor: 3 },
    { number: 'C102', campus: CampusType.WEST, capacity: 45, type: RoomType.ORDINARY, building: '教学楼C', floor: 1 },
    { number: 'D202', campus: CampusType.SOUTH, capacity: 30, type: RoomType.LABORATORY, building: '实验楼D', floor: 2 },
    { number: 'A302', campus: CampusType.MAIN, capacity: 150, type: RoomType.LECTURE_HALL, building: '教学楼A', floor: 3 },
    { number: 'B101', campus: CampusType.EAST, capacity: 50, type: RoomType.COMPUTER_ROOM, building: '信息楼B', floor: 1 },
    { number: 'C201', campus: CampusType.WEST, capacity: 70, type: RoomType.MULTI_FUNCTION, building: '教学楼C', floor: 2 }
  ]
  
  roomData.forEach((room, index) => {
    const allTimeSlots: TimeSlot[] = []
    dates.forEach(date => {
      allTimeSlots.push(...generateTimeSlotsForDate(date))
    })
    
    classrooms.push({
      id: `room-${index}`,
      roomNumber: room.number,
      campus: room.campus,
      capacity: room.capacity,
      type: room.type,
      building: room.building,
      floor: room.floor,
      hasProjector: room.type !== RoomType.COMPUTER_ROOM,
      hasComputer: room.type === RoomType.COMPUTER_ROOM,
      timeSlots: allTimeSlots
    })
  })
  
  return classrooms
}

// 格式化日期显示
export function formatDateDisplay(dateStr: string): string {
  const date = new Date(dateStr)
  const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
  const month = date.getMonth() + 1
  const day = date.getDate()
  const weekday = weekdays[date.getDay()]
  return `${month}月${day}日 ${weekday}`
}

// 获取状态颜色
export function getStatusColor(status: TimeSlotStatus): string {
  switch (status) {
    case TimeSlotStatus.AVAILABLE:
      return '#52c41a' // 绿色
    case TimeSlotStatus.OCCUPIED:
      return '#ff4d4f' // 红色
    case TimeSlotStatus.LOCKED:
      return '#faad14' // 橙色
    case TimeSlotStatus.BOOKED:
      return '#1890ff' // 蓝色
    default:
      return '#d9d9d9' // 灰色
  }
}

// 获取教室类型图标
export function getRoomTypeIcon(type: RoomType): string {
  switch (type) {
    case RoomType.LECTURE_HALL:
      return '🎓'
    case RoomType.MULTI_FUNCTION:
      return '🏛️'
    case RoomType.COMPUTER_ROOM:
      return '💻'
    case RoomType.LABORATORY:
      return '🔬'
    default:
      return '🏫'
  }
}
