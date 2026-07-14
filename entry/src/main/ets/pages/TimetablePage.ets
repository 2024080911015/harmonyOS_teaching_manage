import { Api } from '../api/Api'
import { TimetableInfo, TimetableScheduleInfo } from '../api/model/CommonModel'
import { PageHeader, LoadingState, EmptyState, StatusPill } from '../components/UiKit'
import { errorMessage, showToast, todayString, weekDayLabel } from '../utils/UiUtils'

@Component
export struct TimetablePage {
  @State date: string = todayString()
  @State timetable: TimetableInfo | null = null
  @State loading: boolean = false

  aboutToAppear(): void {
    this.loadTimetable()
  }

  private async loadTimetable(): Promise<void> {
    if (this.date.length !== 10) {
      showToast(this.getUIContext(), { message: '请输入 YYYY-MM-DD 格式的日期' })
      return
    }
    this.loading = true
    try {
      this.timetable = await Api.common.getMyTimetable(this.date)
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    } finally {
      this.loading = false
    }
  }

  build() {
    Column({ space: 16 }) {
      Column({ space: 14 }) {
        PageHeader({ title: '我的课表', subtitle: '已自动合并审批通过的调课安排' })
        Row({ space: 10 }) {
          TextInput({ placeholder: 'YYYY-MM-DD', text: this.date })
            .layoutWeight(1)
            .height(44)
            .fontSize(14)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .padding({ left: 13, right: 13 })
            .onChange((value: string) => this.date = value)
          Button('查询')
            .height(44)
            .fontSize(14)
            .backgroundColor('#2F6B5F')
            .borderRadius(12)
            .onClick(() => this.loadTimetable())
        }
      }
      .padding({ left: 18, right: 18, top: 18 })

      if (this.loading) {
        LoadingState({ text: '正在读取课表' })
      } else if (this.timetable === null || this.timetable!.schedules.length === 0) {
        EmptyState({ title: '当天没有课程', description: '换个日期看看，或享受轻松的一天', symbol: '表' })
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Row() {
              Text(this.timetable!.semester !== null ? this.timetable!.semester!.semesterName : '当前学期')
                .fontSize(13)
                .fontColor('#66717E')
              Blank()
              Text(this.timetable!.week !== null ? `第 ${this.timetable!.week} 教学周` : '')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor('#2F6B5F')
            }
            .width('100%')
            .padding({ left: 2, right: 2 })

            ForEach(this.timetable!.schedules, (item: TimetableScheduleInfo) => {
              Row({ space: 14 }) {
                Column({ space: 3 }) {
                  Text(`${item.effectiveStartSection}`)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#2F6B5F')
                  Text(`至 ${item.effectiveEndSection} 节`)
                    .fontSize(10)
                    .fontColor('#87919D')
                }
                .width(50)
                .alignItems(HorizontalAlign.Center)

                Column({ space: 6 }) {
                  Row() {
                    Text(item.courseName)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#26313B')
                      .maxLines(1)
                      .layoutWeight(1)
                    if (item.changed) {
                      StatusPill({ text: '已调课', color: '#7A5AA6', pillColor: '#F2ECFA' })
                    }
                  }
                  .width('100%')
                  Text(`${weekDayLabel(item.effectiveWeekDay)} · ${item.effectiveClassroomName ?? item.classroomName}`)
                    .fontSize(13)
                    .fontColor('#5E6976')
                  Text(`${item.courseCode} · ${item.teacherName}`)
                    .fontSize(11)
                    .fontColor('#929AA5')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .shadow({ radius: 10, color: '#0D000000', offsetY: 2 })
            }, (item: TimetableScheduleInfo) => `${item.id}-${item.changeId}`)
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
}
