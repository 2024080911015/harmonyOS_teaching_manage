import { Api } from '../api/Api'
import { CourseSelectionStatus, EnrollmentStatus, UserRole } from '../api/core/ApiTypes'
import {
  CourseInfo,
  CourseScheduleInfo,
  CourseStudentInfo,
  EnrollmentRecordInfo
} from '../api/model/CourseModel'
import { PageHeader, LoadingState, EmptyState, StatusPill, SecondaryButton } from '../components/UiKit'
import {
  errorMessage,
  showToast,
  statusBackground,
  statusColor,
  statusLabel,
  weekDayLabel,
  weekTypeLabel
} from '../utils/UiUtils'

@Component
export struct CoursePage {
  @Prop role: UserRole = UserRole.STUDENT

  @State loading: boolean = false
  @State keyword: string = ''
  @State currentView: number = 0
  @State courses: Array<CourseInfo> = []
  @State enrollments: Array<EnrollmentRecordInfo> = []
  @State students: Array<CourseStudentInfo> = []
  @State selectedCourseId: number = 0

  aboutToAppear(): void {
    this.loadData()
  }

  private async loadData(): Promise<void> {
    this.loading = true
    try {
      if (this.role === UserRole.TEACHER) {
        this.courses = await Api.course.getTeachingCourses()
      } else if (this.role === UserRole.STUDENT && this.currentView === 1) {
        this.enrollments = await Api.course.getMyEnrollments()
      } else {
        const page = await Api.course.getCourses({
          page: 1,
          pageSize: 100,
          keyword: this.keyword.length > 0 ? this.keyword : undefined
        })
        this.courses = page.items
      }
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    } finally {
      this.loading = false
    }
  }

  private async enroll(courseId: number): Promise<void> {
    try {
      await Api.course.enroll(courseId)
      showToast(this.getUIContext(), { message: '选课成功' })
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async drop(courseId: number): Promise<void> {
    try {
      await Api.course.drop(courseId)
      showToast(this.getUIContext(), { message: '退课成功' })
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async showStudents(courseId: number): Promise<void> {
    if (this.selectedCourseId === courseId) {
      this.selectedCourseId = 0
      this.students = []
      return
    }
    try {
      this.students = await Api.course.getCourseStudents(courseId)
      this.selectedCourseId = courseId
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  build() {
    Column({ space: 14 }) {
      Column({ space: 14 }) {
        PageHeader({
          title: this.role === UserRole.TEACHER ? '授课课程' : '课程中心',
          subtitle: this.role === UserRole.STUDENT ? '查询课程、完成选课并管理已选课程' : '课程安排与教学名单一目了然'
        })

        if (this.role === UserRole.STUDENT) {
          Row({ space: 6 }) {
            this.ViewChip('全部课程', 0)
            this.ViewChip('我的课程', 1)
          }
        }

        if (this.role !== UserRole.TEACHER && this.currentView === 0) {
          Row({ space: 10 }) {
            TextInput({ placeholder: '搜索课程名称或课程号', text: this.keyword })
              .layoutWeight(1)
              .height(42)
              .fontSize(14)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .padding({ left: 13, right: 13 })
              .onChange((value: string) => this.keyword = value)
              .onSubmit(() => this.loadData())
            Button('搜索')
              .height(42)
              .fontSize(13)
              .backgroundColor('#2F6B5F')
              .borderRadius(12)
              .onClick(() => this.loadData())
          }
        }
      }
      .padding({ left: 18, right: 18, top: 18 })

      if (this.loading) {
        LoadingState({ text: '正在加载课程' })
      } else {
        Scroll() {
          Column({ space: 12 }) {
            if (this.role === UserRole.STUDENT && this.currentView === 1) {
              if (this.enrollments.length === 0) {
                EmptyState({ title: '还没有已选课程', description: '去全部课程中挑选感兴趣的课吧', symbol: '课' })
              } else {
                ForEach(this.enrollments, (record: EnrollmentRecordInfo) => {
                  this.EnrollmentCard(record)
                }, (record: EnrollmentRecordInfo) => `${record.id}-${record.status}`)
              }
            } else if (this.courses.length === 0) {
              EmptyState({ title: '没有找到课程', description: '尝试更换搜索关键词', symbol: '课' })
            } else {
              ForEach(this.courses, (course: CourseInfo) => {
                this.CourseCard(course)
                if (this.role === UserRole.TEACHER && this.selectedCourseId === course.id) {
                  this.StudentList()
                }
              }, (course: CourseInfo) => `${course.id}-${course.selectedCount}`)
            }
          }
          .width('100%')
          .padding({ left: 18, right: 18, bottom: 110 })
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7F6')
  }

  @Builder
  private ViewChip(title: string, index: number) {
    Text(title)
      .fontSize(13)
      .fontWeight(this.currentView === index ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.currentView === index ? '#FFFFFF' : '#65717E')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.currentView === index ? '#2F6B5F' : '#E8ECEA')
      .borderRadius(18)
      .onClick(() => {
        this.currentView = index
        this.loadData()
      })
  }

  @Builder
  private CourseCard(course: CourseInfo) {
    Column({ space: 11 }) {
      Row() {
        Column({ space: 4 }) {
          Text(course.courseName)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#27313B')
            .maxLines(1)
          Text(`${course.courseCode} · ${course.departmentName}`)
            .fontSize(11)
            .fontColor('#8B94A0')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        StatusPill({
          text: statusLabel(course.selectionStatus),
          color: statusColor(course.selectionStatus),
          pillColor: statusBackground(course.selectionStatus)
        })
      }
      Row({ space: 18 }) {
        Text(`${course.credit} 学分`).fontSize(12).fontColor('#5F6B77')
        Text(`${course.teacherName ?? '待定教师'}`).fontSize(12).fontColor('#5F6B77')
        Text(`${course.selectedCount}/${course.capacity} 人`).fontSize(12).fontColor('#5F6B77')
      }
      .width('100%')

      if (course.schedules.length > 0) {
        ForEach(course.schedules, (schedule: CourseScheduleInfo) => {
          Text(`${weekDayLabel(schedule.weekDay)} 第${schedule.startSection}-${schedule.endSection}节 · ${schedule.classroomName} · ${weekTypeLabel(schedule.weekType)}`)
            .fontSize(11)
            .fontColor('#66717E')
            .width('100%')
        }, (schedule: CourseScheduleInfo) => `${schedule.id}`)
      }

      if (this.role === UserRole.STUDENT) {
        Row() {
          Text(`剩余 ${course.remainingCount} 个名额`)
            .fontSize(11)
            .fontColor(course.remainingCount > 0 ? '#2F6B5F' : '#B53A3A')
          Blank()
          Button('选择课程')
            .height(36)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#2F6B5F')
            .borderRadius(10)
            .enabled(course.selectionStatus === CourseSelectionStatus.OPEN && course.remainingCount > 0)
            .onClick(() => this.enroll(course.id))
        }
        .width('100%')
      } else if (this.role === UserRole.TEACHER) {
        Row() {
          Text(`${course.selectedCount} 名学生已选课`)
            .fontSize(12)
            .fontColor('#64707D')
          Blank()
          SecondaryButton({
            text: this.selectedCourseId === course.id ? '收起名单' : '查看名单',
            onTap: () => this.showStudents(course.id)
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 10, color: '#0C000000', offsetY: 2 })
  }

  @Builder
  private EnrollmentCard(record: EnrollmentRecordInfo) {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 4 }) {
          Text(record.courseName)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#27313B')
          Text(`${record.courseCode} · ${record.teacherName}`)
            .fontSize(11)
            .fontColor('#8A94A0')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        StatusPill({
          text: statusLabel(record.status),
          color: statusColor(record.status),
          pillColor: statusBackground(record.status)
        })
      }
      Row() {
        Text(`${record.credit} 学分 · ${record.selectedAt.substring(0, 10)} 选课`)
          .fontSize(11)
          .fontColor('#687481')
        Blank()
        if (record.status === EnrollmentStatus.SELECTED) {
          SecondaryButton({ text: '退课', danger: true, onTap: () => this.drop(record.courseId) })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  private StudentList() {
    Column({ space: 10 }) {
      Text(`课程名单 · ${this.students.length} 人`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#41505E')
        .width('100%')
      if (this.students.length === 0) {
        Text('暂无学生选课')
          .fontSize(12)
          .fontColor('#9099A4')
          .width('100%')
      } else {
        ForEach(this.students, (student: CourseStudentInfo) => {
          Row() {
            Text(student.realName)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#303B46')
            Blank()
            Text(`${student.studentNo} · ${student.className ?? '未分班'}`)
              .fontSize(11)
              .fontColor('#7C8793')
          }
          .width('100%')
          .padding({ top: 7, bottom: 7 })
        }, (student: CourseStudentInfo) => `${student.userId}`)
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#EAF2EF')
    .borderRadius(14)
  }
}
