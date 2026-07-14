import { Api } from '../api/Api'
import {
  BookingStatus,
  LeaveStatus,
  LeaveType,
  ScheduleChangeStatus,
  ScheduleChangeType,
  UserRole
} from '../api/core/ApiTypes'
import { BookingInfo } from '../api/model/BookingModel'
import { ClassroomInfo } from '../api/model/CommonModel'
import { EnrollmentRecordInfo, TeachingScheduleInfo } from '../api/model/CourseModel'
import { LeaveInfo } from '../api/model/LeaveModel'
import { ScheduleChangeInfo } from '../api/model/ScheduleChangeModel'
import {
  EmptyState,
  LoadingState,
  PageHeader,
  SecondaryButton,
  StatusPill
} from '../components/UiKit'
import {
  errorMessage,
  showToast,
  leaveTypeLabel,
  statusBackground,
  statusColor,
  statusLabel,
  todayString,
  weekDayLabel
} from '../utils/UiUtils'

@Component
export struct WorkflowPage {
  @Prop role: UserRole = UserRole.STUDENT

  @State currentSection: number = 0
  @State loading: boolean = false
  @State showForm: boolean = false
  @State reviewComment: string = ''

  @State bookings: Array<BookingInfo> = []
  @State leaves: Array<LeaveInfo> = []
  @State changes: Array<ScheduleChangeInfo> = []
  @State classrooms: Array<ClassroomInfo> = []
  @State enrollments: Array<EnrollmentRecordInfo> = []
  @State teachingSchedules: Array<TeachingScheduleInfo> = []

  @State selectedClassroomId: number = 0
  @State bookingDate: string = todayString()
  @State startSection: string = '1'
  @State endSection: string = '2'
  @State participantCount: string = '30'
  @State purpose: string = ''

  @State leaveType: LeaveType = LeaveType.SICK
  @State leaveStartDate: string = todayString()
  @State leaveEndDate: string = todayString()
  @State leaveReason: string = ''
  @State selectedCourseIds: Array<number> = []

  @State selectedScheduleId: number = 0
  @State changeType: ScheduleChangeType = ScheduleChangeType.TIME
  @State changeReason: string = ''
  @State newWeek: string = '1'
  @State newWeekDay: string = '1'
  @State newStartSection: string = '1'
  @State newEndSection: string = '2'
  @State newClassroomId: number = 0

  aboutToAppear(): void {
    this.loadData()
  }

  private sectionCount(): number {
    if (this.role === UserRole.STUDENT || this.role === UserRole.TEACHER) {
      return 2
    }
    return 3
  }

  private sectionTitle(index: number): string {
    if (this.role === UserRole.STUDENT) {
      return index === 0 ? '教室申请' : '请假申请'
    }
    if (this.role === UserRole.TEACHER) {
      return index === 0 ? '教室申请' : '调课申请'
    }
    if (index === 0) {
      return '教室审批'
    }
    if (index === 1) {
      return '请假审批'
    }
    return '调课审批'
  }

  private async loadData(): Promise<void> {
    this.loading = true
    this.showForm = false
    try {
      if (this.role === UserRole.STUDENT || this.role === UserRole.TEACHER) {
        if (this.currentSection === 0) {
          this.bookings = await Api.booking.getMyBookings()
          this.classrooms = await Api.common.getClassrooms()
        } else if (this.role === UserRole.STUDENT) {
          this.leaves = await Api.leave.getMyLeaves()
          this.enrollments = await Api.course.getMyEnrollments()
        } else {
          this.changes = await Api.scheduleChange.getMyChanges()
          this.teachingSchedules = await Api.course.getTeachingSchedules()
          this.classrooms = await Api.common.getClassrooms()
        }
      } else if (this.currentSection === 0) {
        this.bookings = await Api.booking.getPending()
      } else if (this.currentSection === 1) {
        this.leaves = await Api.leave.getPending()
      } else {
        this.changes = await Api.scheduleChange.getPending()
      }
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    } finally {
      this.loading = false
    }
  }

  private selectSection(index: number): void {
    this.currentSection = index
    this.loadData()
  }

  private toggleCourse(courseId: number): void {
    const index: number = this.selectedCourseIds.indexOf(courseId)
    const next: Array<number> = this.selectedCourseIds.slice()
    if (index >= 0) {
      next.splice(index, 1)
    } else {
      next.push(courseId)
    }
    this.selectedCourseIds = next
  }

  private async submitBooking(): Promise<void> {
    if (this.selectedClassroomId <= 0 || this.purpose.trim().length === 0) {
      showToast(this.getUIContext(), { message: '请选择教室并填写用途' })
      return
    }
    try {
      await Api.booking.create({
        classroomId: this.selectedClassroomId,
        bookingDate: this.bookingDate,
        startSection: Number(this.startSection),
        endSection: Number(this.endSection),
        purpose: this.purpose.trim(),
        participantCount: Number(this.participantCount)
      })
      showToast(this.getUIContext(), { message: '教室申请已提交' })
      this.purpose = ''
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async cancelBooking(id: number): Promise<void> {
    try {
      await Api.booking.cancel(id, '申请人主动取消')
      showToast(this.getUIContext(), { message: '申请已取消' })
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async submitLeave(): Promise<void> {
    if (this.leaveReason.trim().length === 0 || this.selectedCourseIds.length === 0) {
      showToast(this.getUIContext(), { message: '请填写原因并选择受影响课程' })
      return
    }
    try {
      await Api.leave.create({
        leaveType: this.leaveType,
        startDate: this.leaveStartDate,
        endDate: this.leaveEndDate,
        reason: this.leaveReason.trim(),
        courseIds: this.selectedCourseIds
      })
      showToast(this.getUIContext(), { message: '请假申请已提交' })
      this.leaveReason = ''
      this.selectedCourseIds = []
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async cancelLeave(id: number): Promise<void> {
    try {
      await Api.leave.cancel(id, '申请人主动取消')
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async submitChange(): Promise<void> {
    if (this.selectedScheduleId <= 0 || this.changeReason.trim().length === 0) {
      showToast(this.getUIContext(), { message: '请选择原排课并填写调课原因' })
      return
    }
    if ((this.changeType === ScheduleChangeType.ROOM || this.changeType === ScheduleChangeType.BOTH) && this.newClassroomId <= 0) {
      showToast(this.getUIContext(), { message: '请选择新教室' })
      return
    }
    try {
      if (this.changeType === ScheduleChangeType.TIME) {
        await Api.scheduleChange.create({
          scheduleId: this.selectedScheduleId,
          changeType: this.changeType,
          reason: this.changeReason.trim(),
          newWeek: Number(this.newWeek),
          newWeekDay: Number(this.newWeekDay),
          newStartSection: Number(this.newStartSection),
          newEndSection: Number(this.newEndSection)
        })
      } else if (this.changeType === ScheduleChangeType.ROOM) {
        await Api.scheduleChange.create({
          scheduleId: this.selectedScheduleId,
          changeType: this.changeType,
          reason: this.changeReason.trim(),
          newClassroomId: this.newClassroomId
        })
      } else {
        await Api.scheduleChange.create({
          scheduleId: this.selectedScheduleId,
          changeType: this.changeType,
          reason: this.changeReason.trim(),
          newClassroomId: this.newClassroomId,
          newWeek: Number(this.newWeek),
          newWeekDay: Number(this.newWeekDay),
          newStartSection: Number(this.newStartSection),
          newEndSection: Number(this.newEndSection)
        })
      }
      showToast(this.getUIContext(), { message: '调课申请已提交' })
      this.changeReason = ''
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async cancelChange(id: number): Promise<void> {
    try {
      await Api.scheduleChange.cancel(id, '申请人主动取消')
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async reviewBooking(id: number, approve: boolean): Promise<void> {
    try {
      if (approve) {
        await Api.booking.approve(id, this.reviewComment)
      } else {
        await Api.booking.reject(id, this.reviewComment.length > 0 ? this.reviewComment : '审批未通过')
      }
      showToast(this.getUIContext(), { message: approve ? '已通过申请' : '已驳回申请' })
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async reviewLeave(id: number, approve: boolean): Promise<void> {
    try {
      if (approve) {
        await Api.leave.approve(id, this.reviewComment)
      } else {
        await Api.leave.reject(id, this.reviewComment.length > 0 ? this.reviewComment : '审批未通过')
      }
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async reviewChange(id: number, approve: boolean): Promise<void> {
    try {
      if (approve) {
        await Api.scheduleChange.approve(id, this.reviewComment)
      } else {
        await Api.scheduleChange.reject(id, this.reviewComment.length > 0 ? this.reviewComment : '审批未通过')
      }
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  build() {
    Column({ space: 14 }) {
      Column({ space: 14 }) {
        PageHeader({
          title: this.role === UserRole.STUDENT || this.role === UserRole.TEACHER ? '事项办理' : '审批中心',
          subtitle: this.role === UserRole.STUDENT || this.role === UserRole.TEACHER ? '在线提交申请并追踪办理状态' : '集中处理教学过程中的待办事项'
        })
        Scroll() {
          Row({ space: 7 }) {
            ForEach(Array.from({ length: this.sectionCount() }, (_value: Object, index: number) => index), (index: number) => {
              Text(this.sectionTitle(index))
                .fontSize(13)
                .fontWeight(this.currentSection === index ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(this.currentSection === index ? '#FFFFFF' : '#61707B')
                .padding({ left: 15, right: 15, top: 8, bottom: 8 })
                .backgroundColor(this.currentSection === index ? '#2F6B5F' : '#E8ECEA')
                .borderRadius(18)
                .onClick(() => this.selectSection(index))
            }, (index: number) => `${index}`)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)

        if (this.role === UserRole.STUDENT || this.role === UserRole.TEACHER) {
          Button(this.showForm ? '收起申请表' : `新建${this.sectionTitle(this.currentSection)}`)
            .width('100%')
            .height(42)
            .fontSize(13)
            .fontColor('#2F6B5F')
            .backgroundColor('#E4F0EC')
            .borderRadius(12)
            .onClick(() => this.showForm = !this.showForm)
        } else {
          TextInput({ placeholder: '审批意见（驳回时建议填写）', text: this.reviewComment })
            .width('100%')
            .height(42)
            .fontSize(13)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => this.reviewComment = value)
        }
      }
      .padding({ left: 18, right: 18, top: 18 })

      Scroll() {
        Column({ space: 12 }) {
          if (this.showForm) {
            if (this.currentSection === 0) {
              this.BookingForm()
            } else if (this.role === UserRole.STUDENT) {
              this.LeaveForm()
            } else if (this.role === UserRole.TEACHER) {
              this.ChangeForm()
            }
          }

          if (this.loading) {
            LoadingState({ text: '正在读取事项' })
          } else if (this.currentSection === 0) {
            if (this.bookings.length === 0) {
              EmptyState({ title: '暂无教室申请', description: '当前没有需要展示的申请记录', symbol: '室' })
            } else {
              ForEach(this.bookings, (item: BookingInfo) => {
                this.BookingCard(item)
              }, (item: BookingInfo) => `${item.id}-${item.status}`)
            }
          } else if ((this.role === UserRole.STUDENT) || ((this.role === UserRole.ACADEMIC_STAFF || this.role === UserRole.ADMIN) && this.currentSection === 1)) {
            if (this.leaves.length === 0) {
              EmptyState({ title: '暂无请假申请', description: '当前没有需要展示的请假记录', symbol: '假' })
            } else {
              ForEach(this.leaves, (item: LeaveInfo) => {
                this.LeaveCard(item)
              }, (item: LeaveInfo) => `${item.id}-${item.status}`)
            }
          } else {
            if (this.changes.length === 0) {
              EmptyState({ title: '暂无调课申请', description: '当前没有需要展示的调课记录', symbol: '调' })
            } else {
              ForEach(this.changes, (item: ScheduleChangeInfo) => {
                this.ChangeCard(item)
              }, (item: ScheduleChangeInfo) => `${item.id}-${item.status}`)
            }
          }
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 110 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7F6')
  }

  @Builder
  private BookingForm() {
    Column({ space: 12 }) {
      Text('新建教室申请')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#27313B')
        .width('100%')
      this.FormInput('预约日期', this.bookingDate, 'YYYY-MM-DD', (value: string) => this.bookingDate = value)
      Row({ space: 10 }) {
        this.CompactInput('开始节次', this.startSection, (value: string) => this.startSection = value)
        this.CompactInput('结束节次', this.endSection, (value: string) => this.endSection = value)
        this.CompactInput('参与人数', this.participantCount, (value: string) => this.participantCount = value)
      }
      Text('选择教室')
        .fontSize(12)
        .fontColor('#697581')
        .width('100%')
      Scroll() {
        Row({ space: 7 }) {
          ForEach(this.classrooms, (room: ClassroomInfo) => {
            Text(`${room.classroomName} · ${room.capacity}人`)
              .fontSize(11)
              .fontColor(this.selectedClassroomId === room.id ? '#FFFFFF' : '#51606D')
              .padding({ left: 11, right: 11, top: 7, bottom: 7 })
              .backgroundColor(this.selectedClassroomId === room.id ? '#2F6B5F' : '#EDF1EF')
              .borderRadius(16)
              .onClick(() => this.selectedClassroomId = room.id)
          }, (room: ClassroomInfo) => `${room.id}`)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      TextArea({ placeholder: '请说明教室用途', text: this.purpose })
        .width('100%')
        .height(82)
        .fontSize(13)
        .backgroundColor('#F3F5F4')
        .borderRadius(10)
        .padding(11)
        .onChange((value: string) => this.purpose = value)
      Button('提交申请')
        .width('100%')
        .height(42)
        .fontSize(13)
        .backgroundColor('#2F6B5F')
        .borderRadius(11)
        .onClick(() => this.submitBooking())
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  private LeaveForm() {
    Column({ space: 12 }) {
      Text('新建请假申请')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#27313B')
        .width('100%')
      Row({ space: 7 }) {
        this.OptionChip('病假', this.leaveType === LeaveType.SICK, () => this.leaveType = LeaveType.SICK)
        this.OptionChip('事假', this.leaveType === LeaveType.PERSONAL, () => this.leaveType = LeaveType.PERSONAL)
        this.OptionChip('其他', this.leaveType === LeaveType.OTHER, () => this.leaveType = LeaveType.OTHER)
      }
      Row({ space: 10 }) {
        this.CompactInput('开始日期', this.leaveStartDate, (value: string) => this.leaveStartDate = value)
        this.CompactInput('结束日期', this.leaveEndDate, (value: string) => this.leaveEndDate = value)
      }
      Text('受影响课程（可多选）')
        .fontSize(12)
        .fontColor('#697581')
        .width('100%')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.enrollments, (record: EnrollmentRecordInfo) => {
          Text(record.courseName)
            .fontSize(11)
            .fontColor(this.selectedCourseIds.indexOf(record.courseId) >= 0 ? '#FFFFFF' : '#53616D')
            .padding({ left: 11, right: 11, top: 7, bottom: 7 })
            .backgroundColor(this.selectedCourseIds.indexOf(record.courseId) >= 0 ? '#2F6B5F' : '#EDF1EF')
            .borderRadius(15)
            .margin({ right: 7, bottom: 7 })
            .onClick(() => this.toggleCourse(record.courseId))
        }, (record: EnrollmentRecordInfo) => `${record.courseId}`)
      }
      .width('100%')
      TextArea({ placeholder: '请详细说明请假原因', text: this.leaveReason })
        .width('100%')
        .height(82)
        .fontSize(13)
        .backgroundColor('#F3F5F4')
        .borderRadius(10)
        .padding(11)
        .onChange((value: string) => this.leaveReason = value)
      Button('提交申请')
        .width('100%')
        .height(42)
        .fontSize(13)
        .backgroundColor('#2F6B5F')
        .borderRadius(11)
        .onClick(() => this.submitLeave())
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  private ChangeForm() {
    Column({ space: 12 }) {
      Text('新建调课申请')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#27313B')
        .width('100%')
      Text('选择原排课')
        .fontSize(12)
        .fontColor('#697581')
        .width('100%')
      ForEach(this.teachingSchedules, (schedule: TeachingScheduleInfo) => {
        Row() {
          Column({ space: 3 }) {
            Text(schedule.courseName)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#303B46')
            Text(`${weekDayLabel(schedule.weekDay)} 第${schedule.startSection}-${schedule.endSection}节 · ${schedule.classroomName}`)
              .fontSize(10)
              .fontColor('#7D8793')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          Text(this.selectedScheduleId === schedule.id ? '✓' : '○')
            .fontSize(18)
            .fontColor(this.selectedScheduleId === schedule.id ? '#2F6B5F' : '#A0A8B2')
        }
        .width('100%')
        .padding(10)
        .backgroundColor(this.selectedScheduleId === schedule.id ? '#EAF4F1' : '#F3F5F4')
        .borderRadius(10)
        .onClick(() => this.selectedScheduleId = schedule.id)
      }, (schedule: TeachingScheduleInfo) => `${schedule.id}`)
      Row({ space: 7 }) {
        this.OptionChip('调整时间', this.changeType === ScheduleChangeType.TIME, () => this.changeType = ScheduleChangeType.TIME)
        this.OptionChip('更换教室', this.changeType === ScheduleChangeType.ROOM, () => this.changeType = ScheduleChangeType.ROOM)
        this.OptionChip('时间和教室', this.changeType === ScheduleChangeType.BOTH, () => this.changeType = ScheduleChangeType.BOTH)
      }
      if (this.changeType !== ScheduleChangeType.ROOM) {
        Row({ space: 8 }) {
          this.CompactInput('新周次', this.newWeek, (value: string) => this.newWeek = value)
          this.CompactInput('星期', this.newWeekDay, (value: string) => this.newWeekDay = value)
        }
        Row({ space: 8 }) {
          this.CompactInput('开始节次', this.newStartSection, (value: string) => this.newStartSection = value)
          this.CompactInput('结束节次', this.newEndSection, (value: string) => this.newEndSection = value)
        }
      }
      if (this.changeType !== ScheduleChangeType.TIME) {
        Scroll() {
          Row({ space: 7 }) {
            ForEach(this.classrooms, (room: ClassroomInfo) => {
              Text(room.classroomName)
                .fontSize(11)
                .fontColor(this.newClassroomId === room.id ? '#FFFFFF' : '#53616D')
                .padding({ left: 11, right: 11, top: 7, bottom: 7 })
                .backgroundColor(this.newClassroomId === room.id ? '#2F6B5F' : '#EDF1EF')
                .borderRadius(15)
                .onClick(() => this.newClassroomId = room.id)
            }, (room: ClassroomInfo) => `${room.id}`)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }
      TextArea({ placeholder: '请说明调课原因', text: this.changeReason })
        .width('100%')
        .height(78)
        .fontSize(13)
        .backgroundColor('#F3F5F4')
        .borderRadius(10)
        .padding(11)
        .onChange((value: string) => this.changeReason = value)
      Button('提交调课申请')
        .width('100%')
        .height(42)
        .fontSize(13)
        .backgroundColor('#2F6B5F')
        .borderRadius(11)
        .onClick(() => this.submitChange())
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  private BookingCard(item: BookingInfo) {
    Column({ space: 9 }) {
      Row() {
        Column({ space: 3 }) {
          Text(item.classroomName)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#27313B')
          Text(`${item.bookingNo} · ${item.applicantName}`)
            .fontSize(10)
            .fontColor('#8B94A0')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        StatusPill({ text: statusLabel(item.status), color: statusColor(item.status), pillColor: statusBackground(item.status) })
      }
      Text(`${item.bookingDate} · 第${item.startSection}-${item.endSection}节 · ${item.participantCount}人`)
        .fontSize(12)
        .fontColor('#596673')
        .width('100%')
      Text(item.purpose)
        .fontSize(12)
        .fontColor('#6E7884')
        .width('100%')
      if (item.reviewComment !== null) {
        Text(`审批意见：${item.reviewComment}`)
          .fontSize(11)
          .fontColor('#7D5C3A')
          .width('100%')
      }
      if ((this.role === UserRole.STUDENT || this.role === UserRole.TEACHER) && item.status === BookingStatus.PENDING) {
        Row() {
          Blank()
          SecondaryButton({ text: '取消申请', danger: true, onTap: () => this.cancelBooking(item.id) })
        }.width('100%')
      } else if (this.role === UserRole.ACADEMIC_STAFF || this.role === UserRole.ADMIN) {
        this.ReviewActions(() => this.reviewBooking(item.id, true), () => this.reviewBooking(item.id, false))
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(15)
  }

  @Builder
  private LeaveCard(item: LeaveInfo) {
    Column({ space: 9 }) {
      Row() {
        Column({ space: 3 }) {
          Text(`${item.applicantName} · ${leaveTypeLabel(item.leaveType)}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#27313B')
          Text(`${item.leaveNo} · ${item.className ?? '未分班'}`)
            .fontSize(10)
            .fontColor('#8B94A0')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        StatusPill({ text: statusLabel(item.status), color: statusColor(item.status), pillColor: statusBackground(item.status) })
      }
      Text(`${item.startDate} 至 ${item.endDate}`)
        .fontSize(12)
        .fontColor('#596673')
        .width('100%')
      Text(`课程：${item.courses.map(course => course.courseName).join('、')}`)
        .fontSize(11)
        .fontColor('#697581')
        .width('100%')
      Text(item.reason)
        .fontSize(12)
        .fontColor('#6E7884')
        .width('100%')
      if (this.role === UserRole.STUDENT && item.status === LeaveStatus.PENDING) {
        Row() { Blank(); SecondaryButton({ text: '取消申请', danger: true, onTap: () => this.cancelLeave(item.id) }) }.width('100%')
      } else if (this.role === UserRole.ACADEMIC_STAFF || this.role === UserRole.ADMIN) {
        this.ReviewActions(() => this.reviewLeave(item.id, true), () => this.reviewLeave(item.id, false))
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(15)
  }

  @Builder
  private ChangeCard(item: ScheduleChangeInfo) {
    Column({ space: 9 }) {
      Row() {
        Column({ space: 3 }) {
          Text(item.courseName)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#27313B')
          Text(`${item.changeNo} · ${item.applicantName}`)
            .fontSize(10)
            .fontColor('#8B94A0')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        StatusPill({ text: statusLabel(item.status), color: statusColor(item.status), pillColor: statusBackground(item.status) })
      }
      Text(`原安排：${weekDayLabel(item.weekDay)} 第${item.startSection}-${item.endSection}节 · ${item.oldClassroomName}`)
        .fontSize(11)
        .fontColor('#697581')
        .width('100%')
      Text(`新安排：${item.newWeekDay !== null ? weekDayLabel(item.newWeekDay) : '时间不变'} ${item.newStartSection !== null ? `第${item.newStartSection}-${item.newEndSection}节` : ''} ${item.newClassroomName ?? ''}`)
        .fontSize(11)
        .fontColor('#2F6B5F')
        .width('100%')
      Text(item.reason)
        .fontSize(12)
        .fontColor('#6E7884')
        .width('100%')
      if (this.role === UserRole.TEACHER && item.status === ScheduleChangeStatus.PENDING) {
        Row() { Blank(); SecondaryButton({ text: '取消申请', danger: true, onTap: () => this.cancelChange(item.id) }) }.width('100%')
      } else if (this.role === UserRole.ACADEMIC_STAFF || this.role === UserRole.ADMIN) {
        this.ReviewActions(() => this.reviewChange(item.id, true), () => this.reviewChange(item.id, false))
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(15)
  }

  @Builder
  private ReviewActions(onApprove: () => void, onReject: () => void) {
    Row({ space: 8 }) {
      Blank()
      Button('驳回')
        .height(36)
        .fontSize(12)
        .fontColor('#B53A3A')
        .backgroundColor('#FDEEEE')
        .borderRadius(9)
        .onClick(() => onReject())
      Button('通过')
        .height(36)
        .fontSize(12)
        .backgroundColor('#2F6B5F')
        .borderRadius(9)
        .onClick(() => onApprove())
    }
    .width('100%')
  }

  @Builder
  private OptionChip(text: string, selected: boolean, onTap: () => void) {
    Text(text)
      .fontSize(11)
      .fontColor(selected ? '#FFFFFF' : '#53616D')
      .padding({ left: 11, right: 11, top: 7, bottom: 7 })
      .backgroundColor(selected ? '#2F6B5F' : '#EDF1EF')
      .borderRadius(15)
      .onClick(() => onTap())
  }

  @Builder
  private FormInput(label: string, value: string, placeholder: string, onChange: (value: string) => void) {
    Column({ space: 5 }) {
      Text(label).fontSize(11).fontColor('#6C7783').width('100%')
      TextInput({ placeholder: placeholder, text: value })
        .width('100%')
        .height(40)
        .fontSize(12)
        .backgroundColor('#F3F5F4')
        .borderRadius(9)
        .padding({ left: 10, right: 10 })
        .onChange((text: string) => onChange(text))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private CompactInput(label: string, value: string, onChange: (value: string) => void) {
    Column({ space: 5 }) {
      Text(label).fontSize(10).fontColor('#6C7783').width('100%')
      TextInput({ text: value })
        .width('100%')
        .height(38)
        .fontSize(11)
        .backgroundColor('#F3F5F4')
        .borderRadius(9)
        .padding({ left: 9, right: 9 })
        .onChange((text: string) => onChange(text))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }
}
