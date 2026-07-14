import { Api } from '../api/Api'
import {
  ClassroomStatus,
  CourseSelectionStatus,
  EnabledStatus,
  RoomType,
  UserRole,
  WeekType
} from '../api/core/ApiTypes'
import { ApprovalRecordInfo, UserSummaryInfo } from '../api/model/AdminModel'
import { ClassGroupInfo, ClassroomInfo, DepartmentInfo, SemesterInfo } from '../api/model/CommonModel'
import { CourseInfo } from '../api/model/CourseModel'
import { EmptyState, LoadingState, PageHeader, SecondaryButton, StatusPill } from '../components/UiKit'
import { errorMessage, showToast, roleLabel, statusBackground, statusColor, statusLabel } from '../utils/UiUtils'

@Component
export struct AdminPage {
  @Prop role: UserRole = UserRole.ACADEMIC_STAFF

  @State currentView: number = 0
  @State loading: boolean = false
  @State showForm: boolean = false
  @State keyword: string = ''
  @State users: Array<UserSummaryInfo> = []
  @State departments: Array<DepartmentInfo> = []
  @State classes: Array<ClassGroupInfo> = []
  @State classrooms: Array<ClassroomInfo> = []
  @State semesters: Array<SemesterInfo> = []
  @State courses: Array<CourseInfo> = []
  @State approvals: Array<ApprovalRecordInfo> = []
  @State basicType: number = 0

  @State account: string = ''
  @State initialPassword: string = 'Test123456'
  @State realName: string = ''
  @State newRole: UserRole = UserRole.STUDENT
  @State departmentId: string = ''
  @State classId: string = ''
  @State identityNo: string = ''

  @State code: string = ''
  @State name: string = ''
  @State extraOne: string = ''
  @State extraTwo: string = ''
  @State capacity: string = '60'

  @State courseCode: string = ''
  @State courseName: string = ''
  @State teacherId: string = ''
  @State credit: string = '2'
  @State selectionStart: string = '2026-09-01 00:00:00'
  @State selectionEnd: string = '2026-09-14 23:59:59'

  @State scheduleCourseId: string = ''
  @State scheduleClassroomId: string = ''
  @State scheduleSemester: string = ''
  @State startWeek: string = '1'
  @State endWeek: string = '16'
  @State weekDay: string = '1'
  @State startSection: string = '1'
  @State endSection: string = '2'

  aboutToAppear(): void {
    this.loadData()
  }

  private async loadData(): Promise<void> {
    this.loading = true
    try {
      if (this.currentView === 0) {
        const page = await Api.admin.getUsers({ page: 1, pageSize: 100, keyword: this.keyword.length > 0 ? this.keyword : undefined })
        this.users = page.items
      } else if (this.currentView === 1) {
        this.departments = await Api.common.getDepartments()
        this.classes = await Api.common.getClasses()
        this.classrooms = await Api.common.getClassrooms()
        this.semesters = await Api.common.getSemesters()
      } else if (this.currentView === 2) {
        const page = await Api.course.getCourses({ page: 1, pageSize: 100 })
        this.courses = page.items
        this.departments = await Api.common.getDepartments()
        this.classrooms = await Api.common.getClassrooms()
        this.semesters = await Api.common.getSemesters()
      } else {
        this.approvals = await Api.admin.getApprovals()
      }
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    } finally {
      this.loading = false
    }
  }

  private switchView(index: number): void {
    this.currentView = index
    this.showForm = false
    this.loadData()
  }

  private async createUser(): Promise<void> {
    if (this.account.trim().length === 0 || this.realName.trim().length === 0 || this.identityNo.trim().length === 0) {
      showToast(this.getUIContext(), { message: '请填写账号、姓名和学工号' })
      return
    }
    try {
      if (this.newRole === UserRole.STUDENT) {
        await Api.admin.createUser({
          account: this.account.trim(), initialPassword: this.initialPassword, realName: this.realName.trim(), role: this.newRole,
          departmentId: Number(this.departmentId), classId: Number(this.classId), studentNo: this.identityNo.trim()
        })
      } else {
        await Api.admin.createUser({
          account: this.account.trim(), initialPassword: this.initialPassword, realName: this.realName.trim(), role: this.newRole,
          departmentId: Number(this.departmentId), employeeNo: this.identityNo.trim()
        })
      }
      showToast(this.getUIContext(), { message: '用户创建成功' })
      this.account = ''
      this.realName = ''
      this.identityNo = ''
      this.showForm = false
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async toggleUser(item: UserSummaryInfo): Promise<void> {
    try {
      await Api.admin.updateUserStatus(item.id, {
        status: item.status === EnabledStatus.ENABLED ? EnabledStatus.DISABLED : EnabledStatus.ENABLED
      })
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async resetPassword(item: UserSummaryInfo): Promise<void> {
    try {
      await Api.admin.resetUserPassword(item.id, { newPassword: 'Test123456' })
      showToast(this.getUIContext(), { message: `已将 ${item.realName} 的密码重置为 Test123456` })
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async createBasic(): Promise<void> {
    if (this.code.trim().length === 0 || this.name.trim().length === 0) {
      showToast(this.getUIContext(), { message: '请填写编码和名称' })
      return
    }
    try {
      if (this.basicType === 0) {
        await Api.admin.createDepartment({ departmentCode: this.code, departmentName: this.name, managerName: this.extraOne })
      } else if (this.basicType === 1) {
        await Api.admin.createClass({
          classCode: this.code, className: this.name, grade: this.extraOne, majorName: this.extraTwo,
          departmentId: Number(this.departmentId)
        })
      } else if (this.basicType === 2) {
        await Api.admin.createClassroom({
          classroomCode: this.code, classroomName: this.name, campus: this.extraOne,
          building: this.extraTwo, roomType: RoomType.MULTIMEDIA, capacity: Number(this.capacity),
          status: ClassroomStatus.AVAILABLE
        })
      } else {
        await Api.admin.createSemester({ semesterCode: this.code, semesterName: this.name, startDate: this.extraOne, endDate: this.extraTwo })
      }
      showToast(this.getUIContext(), { message: '基础数据创建成功' })
      this.code = ''
      this.name = ''
      this.showForm = false
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async createCourse(): Promise<void> {
    try {
      await Api.admin.createCourse({
        courseCode: this.courseCode, courseName: this.courseName, teacherId: Number(this.teacherId),
        departmentId: Number(this.departmentId), capacity: Number(this.capacity), credit: Number(this.credit),
        selectionStart: this.selectionStart, selectionEnd: this.selectionEnd,
        selectionStatus: CourseSelectionStatus.CLOSED, status: EnabledStatus.ENABLED
      })
      showToast(this.getUIContext(), { message: '课程创建成功' })
      this.showForm = false
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async createSchedule(): Promise<void> {
    try {
      await Api.admin.createSchedule({
        courseId: Number(this.scheduleCourseId), classroomId: Number(this.scheduleClassroomId), semester: this.scheduleSemester,
        startWeek: Number(this.startWeek), endWeek: Number(this.endWeek), weekDay: Number(this.weekDay),
        startSection: Number(this.startSection), endSection: Number(this.endSection), weekType: WeekType.ALL
      })
      showToast(this.getUIContext(), { message: '排课创建成功' })
      this.showForm = false
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async toggleCourse(item: CourseInfo): Promise<void> {
    try {
      await Api.admin.updateCourseStatus(item.id, {
        status: item.status === EnabledStatus.ENABLED ? EnabledStatus.DISABLED : EnabledStatus.ENABLED,
        selectionStatus: item.selectionStatus
      })
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  build() {
    Column({ space: 14 }) {
      Column({ space: 14 }) {
        PageHeader({ title: '教学管理', subtitle: '人员、基础数据、课程排课与审批记录' })
        Scroll() {
          Row({ space: 7 }) {
            this.ViewChip('人员', 0)
            this.ViewChip('基础数据', 1)
            this.ViewChip('课程排课', 2)
            this.ViewChip('审批记录', 3)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        if (this.currentView !== 3) {
          Row({ space: 9 }) {
            if (this.currentView === 0) {
              TextInput({ placeholder: '搜索姓名或账号', text: this.keyword })
                .layoutWeight(1).height(40).fontSize(12).backgroundColor('#FFFFFF').borderRadius(10).padding({ left: 10, right: 10 })
                .onChange((value: string) => this.keyword = value).onSubmit(() => this.loadData())
              Button('搜索').height(40).fontSize(12).backgroundColor('#64746E').borderRadius(10).onClick(() => this.loadData())
            } else if (this.currentView === 1) {
              this.BasicChip('院系', 0); this.BasicChip('班级', 1); this.BasicChip('教室', 2); this.BasicChip('学期', 3)
            } else {
              this.BasicChip('新建课程', 0); this.BasicChip('新增排课', 1)
            }
            Blank()
            Button(this.showForm ? '收起' : '新增')
              .height(40).fontSize(12).fontColor('#2F6B5F').backgroundColor('#E4F0EC').borderRadius(10)
              .onClick(() => this.showForm = !this.showForm)
          }
          .width('100%')
        }
      }
      .padding({ left: 18, right: 18, top: 18 })

      Scroll() {
        Column({ space: 12 }) {
          if (this.showForm) {
            if (this.currentView === 0) {
              this.UserForm()
            } else if (this.currentView === 1) {
              this.BasicForm()
            } else if (this.basicType === 0) {
              this.CourseForm()
            } else {
              this.ScheduleForm()
            }
          }
          if (this.loading) {
            LoadingState({ text: '正在加载管理数据' })
          } else if (this.currentView === 0) {
            if (this.users.length === 0) { EmptyState({ title: '没有找到用户', symbol: '人' }) }
            else { ForEach(this.users, (item: UserSummaryInfo) => { this.UserCard(item) }, (item: UserSummaryInfo) => `${item.id}-${item.status}`) }
          } else if (this.currentView === 1) {
            this.BasicList()
          } else if (this.currentView === 2) {
            if (this.courses.length === 0) { EmptyState({ title: '暂无课程', symbol: '课' }) }
            else { ForEach(this.courses, (item: CourseInfo) => { this.CourseCard(item) }, (item: CourseInfo) => `${item.id}-${item.status}`) }
          } else {
            if (this.approvals.length === 0) { EmptyState({ title: '暂无审批记录', symbol: '审' }) }
            else { ForEach(this.approvals, (item: ApprovalRecordInfo) => { this.ApprovalCard(item) }, (item: ApprovalRecordInfo) => `${item.id}`) }
          }
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 110 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%').height('100%').backgroundColor('#F5F7F6')
  }

  @Builder private ViewChip(text: string, index: number) {
    Text(text).fontSize(12).fontColor(this.currentView === index ? '#FFFFFF' : '#5F6D79')
      .padding({ left: 13, right: 13, top: 8, bottom: 8 }).backgroundColor(this.currentView === index ? '#2F6B5F' : '#E8ECEA').borderRadius(17)
      .onClick(() => this.switchView(index))
  }

  @Builder private BasicChip(text: string, index: number) {
    Text(text).fontSize(10).fontColor(this.basicType === index ? '#FFFFFF' : '#5F6D79')
      .padding({ left: 9, right: 9, top: 6, bottom: 6 }).backgroundColor(this.basicType === index ? '#64746E' : '#E8ECEA').borderRadius(14)
      .onClick(() => this.basicType = index)
  }

  @Builder private UserForm() {
    Column({ space: 10 }) {
      Text('创建用户').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#27313B').width('100%')
      Row({ space: 6 }) {
        this.RoleChip('学生', UserRole.STUDENT); this.RoleChip('教师', UserRole.TEACHER); this.RoleChip('教务', UserRole.ACADEMIC_STAFF)
        if (this.role === UserRole.ADMIN) { this.RoleChip('管理员', UserRole.ADMIN) }
      }
      this.InputField('登录账号', this.account, (v: string) => this.account = v)
      this.InputField('姓名', this.realName, (v: string) => this.realName = v)
      this.InputField(this.newRole === UserRole.STUDENT ? '学号' : '工号', this.identityNo, (v: string) => this.identityNo = v)
      Row({ space: 8 }) {
        this.CompactField('院系 ID', this.departmentId, (v: string) => this.departmentId = v)
        if (this.newRole === UserRole.STUDENT) { this.CompactField('班级 ID', this.classId, (v: string) => this.classId = v) }
      }
      this.InputField('初始密码', this.initialPassword, (v: string) => this.initialPassword = v)
      Button('创建用户').width('100%').height(41).fontSize(12).backgroundColor('#2F6B5F').borderRadius(10).onClick(() => this.createUser())
    }.width('100%').padding(15).backgroundColor('#FFFFFF').borderRadius(15)
  }

  @Builder private BasicForm() {
    Column({ space: 10 }) {
      Text(`新增${this.basicType === 0 ? '院系' : this.basicType === 1 ? '班级' : this.basicType === 2 ? '教室' : '学期'}`)
        .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#27313B').width('100%')
      this.InputField('编码', this.code, (v: string) => this.code = v)
      this.InputField('名称', this.name, (v: string) => this.name = v)
      if (this.basicType === 0) { this.InputField('负责人', this.extraOne, (v: string) => this.extraOne = v) }
      else if (this.basicType === 1) {
        this.InputField('年级', this.extraOne, (v: string) => this.extraOne = v); this.InputField('专业', this.extraTwo, (v: string) => this.extraTwo = v)
        this.InputField('院系 ID', this.departmentId, (v: string) => this.departmentId = v)
      } else if (this.basicType === 2) {
        this.InputField('校区', this.extraOne, (v: string) => this.extraOne = v); this.InputField('教学楼', this.extraTwo, (v: string) => this.extraTwo = v)
        this.InputField('容量', this.capacity, (v: string) => this.capacity = v)
      } else {
        this.InputField('开始日期 YYYY-MM-DD', this.extraOne, (v: string) => this.extraOne = v); this.InputField('结束日期 YYYY-MM-DD', this.extraTwo, (v: string) => this.extraTwo = v)
      }
      Button('确认创建').width('100%').height(41).fontSize(12).backgroundColor('#2F6B5F').borderRadius(10).onClick(() => this.createBasic())
    }.width('100%').padding(15).backgroundColor('#FFFFFF').borderRadius(15)
  }

  @Builder private CourseForm() {
    Column({ space: 10 }) {
      Text('新建课程').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#27313B').width('100%')
      this.InputField('课程号', this.courseCode, (v: string) => this.courseCode = v); this.InputField('课程名称', this.courseName, (v: string) => this.courseName = v)
      Row({ space: 8 }) { this.CompactField('教师 ID', this.teacherId, (v: string) => this.teacherId = v); this.CompactField('院系 ID', this.departmentId, (v: string) => this.departmentId = v) }
      Row({ space: 8 }) { this.CompactField('容量', this.capacity, (v: string) => this.capacity = v); this.CompactField('学分', this.credit, (v: string) => this.credit = v) }
      this.InputField('选课开始 YYYY-MM-DD HH:mm:ss', this.selectionStart, (v: string) => this.selectionStart = v)
      this.InputField('选课结束 YYYY-MM-DD HH:mm:ss', this.selectionEnd, (v: string) => this.selectionEnd = v)
      Button('创建课程').width('100%').height(41).fontSize(12).backgroundColor('#2F6B5F').borderRadius(10).onClick(() => this.createCourse())
    }.width('100%').padding(15).backgroundColor('#FFFFFF').borderRadius(15)
  }

  @Builder private ScheduleForm() {
    Column({ space: 10 }) {
      Text('新增排课').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#27313B').width('100%')
      Row({ space: 8 }) { this.CompactField('课程 ID', this.scheduleCourseId, (v: string) => this.scheduleCourseId = v); this.CompactField('教室 ID', this.scheduleClassroomId, (v: string) => this.scheduleClassroomId = v) }
      this.InputField('学期编码', this.scheduleSemester, (v: string) => this.scheduleSemester = v)
      Row({ space: 8 }) { this.CompactField('开始周', this.startWeek, (v: string) => this.startWeek = v); this.CompactField('结束周', this.endWeek, (v: string) => this.endWeek = v); this.CompactField('星期', this.weekDay, (v: string) => this.weekDay = v) }
      Row({ space: 8 }) { this.CompactField('开始节次', this.startSection, (v: string) => this.startSection = v); this.CompactField('结束节次', this.endSection, (v: string) => this.endSection = v) }
      Button('创建排课').width('100%').height(41).fontSize(12).backgroundColor('#2F6B5F').borderRadius(10).onClick(() => this.createSchedule())
    }.width('100%').padding(15).backgroundColor('#FFFFFF').borderRadius(15)
  }

  @Builder private UserCard(item: UserSummaryInfo) {
    Column({ space: 9 }) {
      Row() {
        Column({ space: 3 }) { Text(item.realName).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#27313B'); Text(`${item.account} · ${roleLabel(item.role)}`).fontSize(10).fontColor('#89939F') }
          .layoutWeight(1).alignItems(HorizontalAlign.Start)
        StatusPill({ text: item.status === EnabledStatus.ENABLED ? '启用' : '停用', color: item.status === EnabledStatus.ENABLED ? '#16805A' : '#C04444', pillColor: item.status === EnabledStatus.ENABLED ? '#EAF8F2' : '#FDECEC' })
      }.width('100%')
      Text(`${item.departmentName ?? '未设置院系'} · ${item.className ?? '无班级'}`).fontSize(11).fontColor('#65717D').width('100%')
      Row({ space: 8 }) { Blank(); SecondaryButton({ text: '重置密码', onTap: () => this.resetPassword(item) }); SecondaryButton({ text: item.status === EnabledStatus.ENABLED ? '停用' : '启用', danger: item.status === EnabledStatus.ENABLED, onTap: () => this.toggleUser(item) }) }.width('100%')
    }.width('100%').padding(15).backgroundColor('#FFFFFF').borderRadius(15)
  }

  @Builder private BasicList() {
    if (this.basicType === 0) {
      ForEach(this.departments, (item: DepartmentInfo) => { this.SimpleCard(item.departmentName, item.departmentCode, item.managerName ?? '未设置负责人') }, (item: DepartmentInfo) => `${item.id}`)
    } else if (this.basicType === 1) {
      ForEach(this.classes, (item: ClassGroupInfo) => { this.SimpleCard(item.className, item.classCode, `${item.grade} · ${item.majorName} · ${item.studentCount}人`) }, (item: ClassGroupInfo) => `${item.id}`)
    } else if (this.basicType === 2) {
      ForEach(this.classrooms, (item: ClassroomInfo) => { this.SimpleCard(item.classroomName, item.classroomCode, `${item.campus} ${item.building} · ${item.capacity}人 · ${statusLabel(item.status)}`) }, (item: ClassroomInfo) => `${item.id}`)
    } else {
      ForEach(this.semesters, (item: SemesterInfo) => { this.SimpleCard(item.semesterName, item.semesterCode, `${item.startDate} 至 ${item.endDate}`) }, (item: SemesterInfo) => `${item.id}`)
    }
  }

  @Builder private SimpleCard(title: string, code: string, detail: string) {
    Column({ space: 5 }) { Row() { Text(title).fontSize(15).fontWeight(FontWeight.Bold).fontColor('#27313B'); Blank(); Text(code).fontSize(10).fontColor('#86919D') }.width('100%'); Text(detail).fontSize(11).fontColor('#65717D').width('100%') }
      .width('100%').padding(14).backgroundColor('#FFFFFF').borderRadius(14).margin({ bottom: 8 })
  }

  @Builder private CourseCard(item: CourseInfo) {
    Column({ space: 8 }) {
      Row() { Column({ space: 3 }) { Text(item.courseName).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#27313B'); Text(`${item.courseCode} · ${item.teacherName ?? '待定教师'}`).fontSize(10).fontColor('#89939F') }.layoutWeight(1).alignItems(HorizontalAlign.Start); StatusPill({ text: statusLabel(item.selectionStatus), color: statusColor(item.selectionStatus), pillColor: statusBackground(item.selectionStatus) }) }.width('100%')
      Text(`${item.credit} 学分 · ${item.selectedCount}/${item.capacity} 人 · ${item.departmentName}`).fontSize(11).fontColor('#65717D').width('100%')
      Row() { Blank(); SecondaryButton({ text: item.status === EnabledStatus.ENABLED ? '停用课程' : '启用课程', danger: item.status === EnabledStatus.ENABLED, onTap: () => this.toggleCourse(item) }) }.width('100%')
    }.width('100%').padding(15).backgroundColor('#FFFFFF').borderRadius(15)
  }

  @Builder private ApprovalCard(item: ApprovalRecordInfo) {
    Column({ space: 6 }) { Row() { Text(item.businessType).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#27313B'); Blank(); Text(item.action === 'APPROVE' ? '已通过' : '已驳回').fontSize(11).fontColor(item.action === 'APPROVE' ? '#16805A' : '#C04444') }.width('100%'); Text(`业务 #${item.businessId} · ${item.approverName} · ${item.createdAt.substring(0, 16)}`).fontSize(10).fontColor('#89939F').width('100%'); if (item.comment !== null) { Text(item.comment).fontSize(11).fontColor('#65717D').width('100%') } }
      .width('100%').padding(14).backgroundColor('#FFFFFF').borderRadius(14)
  }

  @Builder private RoleChip(text: string, role: UserRole) {
    Text(text).fontSize(10).fontColor(this.newRole === role ? '#FFFFFF' : '#566470').padding({ left: 10, right: 10, top: 7, bottom: 7 }).backgroundColor(this.newRole === role ? '#2F6B5F' : '#EDF1EF').borderRadius(14).onClick(() => this.newRole = role)
  }
  @Builder private InputField(placeholder: string, value: string, onChange: (v: string) => void) {
    TextInput({ placeholder: placeholder, text: value }).width('100%').height(40).fontSize(12).backgroundColor('#F3F5F4').borderRadius(9).padding({ left: 10, right: 10 }).onChange((text: string) => onChange(text))
  }
  @Builder private CompactField(placeholder: string, value: string, onChange: (v: string) => void) {
    TextInput({ placeholder: placeholder, text: value }).layoutWeight(1).height(40).fontSize(11).backgroundColor('#F3F5F4').borderRadius(9).padding({ left: 9, right: 9 }).onChange((text: string) => onChange(text))
  }
}
