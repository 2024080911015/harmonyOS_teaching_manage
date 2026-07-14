import { Api } from '../api/Api'
import { UserRole } from '../api/core/ApiTypes'
import {
  HomeInfo,
  ManagerHomeSummary,
  StudentHomeSummary,
  TeacherHomeSummary
} from '../api/model/ProfileModel'
import { ReceivedNotificationInfo } from '../api/model/NotificationModel'
import { MetricCard, SectionTitle, LoadingState, EmptyState } from '../components/UiKit'
import { errorMessage, showToast, roleLabel } from '../utils/UiUtils'

@Component
export struct HomePage {
  @Prop role: UserRole = UserRole.STUDENT
  @Prop realName: string = ''
  onNavigate: (index: number) => void = (_index: number): void => {}

  @State loading: boolean = true
  @State headline: string = ''
  @State metricOne: string = '0'
  @State metricTwo: string = '0'
  @State metricThree: string = '0'
  @State unreadCount: string = '0'
  @State notifications: Array<ReceivedNotificationInfo> = []

  aboutToAppear(): void {
    this.loadData()
  }

  private async loadData(): Promise<void> {
    this.loading = true
    try {
      const home: HomeInfo = await Api.profile.getHome()
      this.headline = home.profile.departmentName !== null
        ? home.profile.departmentName
        : roleLabel(this.role)

      if (this.role === UserRole.STUDENT) {
        const summary: StudentHomeSummary = home.summary as StudentHomeSummary
        this.metricOne = `${summary.selectedCourseCount}`
        this.metricTwo = `${summary.pendingBookingCount}`
        this.metricThree = `${summary.pendingLeaveCount}`
        this.unreadCount = `${summary.unreadNotificationCount}`
      } else if (this.role === UserRole.TEACHER) {
        const summary: TeacherHomeSummary = home.summary as TeacherHomeSummary
        this.metricOne = `${summary.teachingCourseCount}`
        this.metricTwo = `${summary.pendingBookingCount}`
        this.metricThree = `${summary.pendingScheduleChangeCount}`
        this.unreadCount = `${summary.unreadNotificationCount}`
      } else {
        const summary: ManagerHomeSummary = home.summary as ManagerHomeSummary
        this.metricOne = `${summary.pendingBookingCount}`
        this.metricTwo = `${summary.pendingLeaveCount}`
        this.metricThree = `${summary.pendingScheduleChangeCount}`
        this.unreadCount = `${summary.unreadNotificationCount}`
      }

      const notices = await Api.notification.getReceived({ page: 1, pageSize: 3 })
      this.notifications = notices.items
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    } finally {
      this.loading = false
    }
  }

  private firstMetricLabel(): string {
    if (this.role === UserRole.STUDENT) {
      return '已选课程'
    }
    if (this.role === UserRole.TEACHER) {
      return '授课课程'
    }
    return '待审教室'
  }

  private secondMetricLabel(): string {
    if (this.role === UserRole.STUDENT || this.role === UserRole.TEACHER) {
      return '待审教室'
    }
    return '待审请假'
  }

  private thirdMetricLabel(): string {
    if (this.role === UserRole.STUDENT) {
      return '待审请假'
    }
    return '待审调课'
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Row() {
          Column({ space: 4 }) {
            Text(`你好，${this.realName}`)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#17202A')
            Text(`${this.headline} · ${roleLabel(this.role)}`)
              .fontSize(13)
              .fontColor('#778190')
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Text(this.realName.length > 0 ? this.realName.substring(0, 1) : '教')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .width(46)
            .height(46)
            .textAlign(TextAlign.Center)
            .backgroundColor('#2F6B5F')
            .borderRadius(15)
        }
        .width('100%')

        if (this.loading) {
          LoadingState({ text: '正在同步教学数据' })
        } else {
          Row({ space: 10 }) {
            MetricCard({ label: this.firstMetricLabel(), value: this.metricOne, icon: '课' })
            MetricCard({ label: this.secondMetricLabel(), value: this.metricTwo, icon: '室', tint: '#936B2D' })
          }
          Row({ space: 10 }) {
            MetricCard({ label: this.thirdMetricLabel(), value: this.metricThree, icon: '审', tint: '#7A5AA6' })
            MetricCard({ label: '未读通知', value: this.unreadCount, icon: '信', tint: '#3C6FA5' })
          }

          Column({ space: 12 }) {
            SectionTitle({ title: '快捷入口', action: '刷新', onAction: () => this.loadData() })
            Row({ space: 10 }) {
              this.QuickEntry('今日课表', '查看今天的课程安排', '表', 1)
              this.QuickEntry(
                this.role === UserRole.STUDENT ? '课程中心' : '教学课程',
                this.role === UserRole.STUDENT ? '选课与退课' : '课程与学生',
                '课',
                2
              )
            }
            Row({ space: 10 }) {
              this.QuickEntry('事项办理', '申请与审批进度', '办', 3)
              this.QuickEntry('消息中心', '查收教学通知', '信', 4)
            }
          }

          Column({ space: 12 }) {
            SectionTitle({ title: '最新通知', action: '查看全部', onAction: () => this.onNavigate(4) })
            if (this.notifications.length === 0) {
              EmptyState({ title: '暂无新通知', description: '重要教学消息会在这里出现', symbol: '信' })
            } else {
              ForEach(this.notifications, (notice: ReceivedNotificationInfo) => {
                Row({ space: 12 }) {
                  Text(notice.isRead === 0 ? '●' : '○')
                    .fontSize(13)
                    .fontColor(notice.isRead === 0 ? '#D2853C' : '#B5BDC7')
                  Column({ space: 4 }) {
                    Text(notice.title)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#27313C')
                      .maxLines(1)
                    Text(`${notice.publisherName} · ${notice.publishedAt.substring(0, 10)}`)
                      .fontSize(11)
                      .fontColor('#8B94A0')
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .padding(14)
                .backgroundColor('#FFFFFF')
                .borderRadius(14)
              }, (notice: ReceivedNotificationInfo) => `${notice.id}`)
            }
          }
        }
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 18, bottom: 110 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7F6')
  }

  @Builder
  private QuickEntry(title: string, description: string, icon: string, index: number) {
    Row({ space: 10 }) {
      Text(icon)
        .fontSize(16)
        .fontColor('#2F6B5F')
        .fontWeight(FontWeight.Bold)
        .width(34)
        .height(34)
        .textAlign(TextAlign.Center)
        .backgroundColor('#EAF4F1')
        .borderRadius(11)
      Column({ space: 2 }) {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#26313B')
        Text(description)
          .fontSize(10)
          .fontColor('#8A94A0')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .onClick(() => this.onNavigate(index))
  }
}
