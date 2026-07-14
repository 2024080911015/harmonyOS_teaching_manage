import { Api } from '../api/Api'
import { NotificationAudienceType, NotificationStatus, UserRole } from '../api/core/ApiTypes'
import {
  ManagedNotificationInfo,
  PublishedNotificationInfo,
  ReceivedNotificationInfo
} from '../api/model/NotificationModel'
import { EmptyState, LoadingState, PageHeader, SecondaryButton, StatusPill } from '../components/UiKit'
import { errorMessage, showToast, futureDateTime, statusBackground, statusColor, statusLabel } from '../utils/UiUtils'

@Component
export struct NotificationPage {
  @Prop role: UserRole = UserRole.STUDENT

  @State currentView: number = 0
  @State loading: boolean = false
  @State showPublish: boolean = false
  @State received: Array<ReceivedNotificationInfo> = []
  @State published: Array<PublishedNotificationInfo> = []
  @State managed: Array<ManagedNotificationInfo> = []
  @State expandedId: number = 0

  @State title: string = ''
  @State content: string = ''
  @State audienceType: NotificationAudienceType = NotificationAudienceType.ALL_STUDENTS
  @State targetId: string = ''
  @State expiresAt: string = futureDateTime(7)

  aboutToAppear(): void {
    this.loadData()
  }

  private canPublish(): boolean {
    return this.role !== UserRole.STUDENT
  }

  private audienceLabel(type: NotificationAudienceType): string {
    if (type === NotificationAudienceType.CLASS) {
      return '指定班级'
    }
    if (type === NotificationAudienceType.DEPARTMENT) {
      return '指定院系'
    }
    if (type === NotificationAudienceType.USER) {
      return '指定用户'
    }
    return '全体学生'
  }

  private async loadData(): Promise<void> {
    this.loading = true
    try {
      if (this.currentView === 0) {
        const page = await Api.notification.getReceived({ page: 1, pageSize: 100 })
        this.received = page.items
      } else if (this.role === UserRole.TEACHER) {
        this.published = await Api.notification.getPublishedByMe()
      } else {
        this.managed = await Api.notification.getManageList()
      }
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    } finally {
      this.loading = false
    }
  }

  private switchView(index: number): void {
    this.currentView = index
    this.expandedId = 0
    this.loadData()
  }

  private async openNotice(item: ReceivedNotificationInfo): Promise<void> {
    this.expandedId = this.expandedId === item.id ? 0 : item.id
    if (item.isRead === 0) {
      try {
        await Api.notification.markRead(item.id)
        await this.loadData()
        this.expandedId = item.id
      } catch (error) {
        showToast(this.getUIContext(), { message: errorMessage(error as Object) })
      }
    }
  }

  private async publish(): Promise<void> {
    if (this.title.trim().length === 0 || this.content.trim().length === 0) {
      showToast(this.getUIContext(), { message: '请填写通知标题和正文' })
      return
    }
    if (this.audienceType !== NotificationAudienceType.ALL_STUDENTS && Number(this.targetId) <= 0) {
      showToast(this.getUIContext(), { message: '请填写有效的目标 ID' })
      return
    }
    try {
      if (this.audienceType === NotificationAudienceType.CLASS) {
        await Api.notification.publish({
          title: this.title.trim(), content: this.content.trim(), audienceType: this.audienceType,
          expiresAt: this.expiresAt, targetClassId: Number(this.targetId)
        })
      } else if (this.audienceType === NotificationAudienceType.DEPARTMENT) {
        await Api.notification.publish({
          title: this.title.trim(), content: this.content.trim(), audienceType: this.audienceType,
          expiresAt: this.expiresAt, targetDepartmentId: Number(this.targetId)
        })
      } else if (this.audienceType === NotificationAudienceType.USER) {
        await Api.notification.publish({
          title: this.title.trim(), content: this.content.trim(), audienceType: this.audienceType,
          expiresAt: this.expiresAt, targetUserId: Number(this.targetId)
        })
      } else {
        await Api.notification.publish({
          title: this.title.trim(), content: this.content.trim(), audienceType: this.audienceType,
          expiresAt: this.expiresAt
        })
      }
      showToast(this.getUIContext(), { message: '通知发布成功' })
      this.title = ''
      this.content = ''
      this.showPublish = false
      this.currentView = 1
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async withdraw(id: number): Promise<void> {
    try {
      await Api.notification.withdraw(id)
      showToast(this.getUIContext(), { message: '通知已撤回' })
      await this.loadData()
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  build() {
    Column({ space: 14 }) {
      Column({ space: 14 }) {
        PageHeader({ title: '消息中心', subtitle: '教学通知、课程提醒和重要事项' })
        Row({ space: 7 }) {
          this.ViewChip('收到的通知', 0)
          if (this.canPublish()) {
            this.ViewChip(this.role === UserRole.TEACHER ? '我发布的' : '通知管理', 1)
            Blank()
            Text(this.showPublish ? '收起' : '发布')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2F6B5F')
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor('#E4F0EC')
              .borderRadius(17)
              .onClick(() => this.showPublish = !this.showPublish)
          }
        }
        .width('100%')
      }
      .padding({ left: 18, right: 18, top: 18 })

      Scroll() {
        Column({ space: 12 }) {
          if (this.showPublish) {
            this.PublishForm()
          }
          if (this.loading) {
            LoadingState({ text: '正在加载通知' })
          } else if (this.currentView === 0) {
            if (this.received.length === 0) {
              EmptyState({ title: '暂无通知', description: '收到的教学消息会显示在这里', symbol: '信' })
            } else {
              ForEach(this.received, (item: ReceivedNotificationInfo) => {
                this.ReceivedCard(item)
              }, (item: ReceivedNotificationInfo) => `${item.id}-${item.isRead}`)
            }
          } else if (this.role === UserRole.TEACHER) {
            if (this.published.length === 0) {
              EmptyState({ title: '还未发布通知', description: '点击右上角发布第一条通知', symbol: '发' })
            } else {
              ForEach(this.published, (item: PublishedNotificationInfo) => {
                this.PublishedCard(item)
              }, (item: PublishedNotificationInfo) => `${item.id}-${item.status}`)
            }
          } else {
            if (this.managed.length === 0) {
              EmptyState({ title: '暂无通知记录', symbol: '信' })
            } else {
              ForEach(this.managed, (item: ManagedNotificationInfo) => {
                this.ManagedCard(item)
              }, (item: ManagedNotificationInfo) => `${item.id}-${item.status}`)
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
  private ViewChip(text: string, index: number) {
    Text(text)
      .fontSize(12)
      .fontColor(this.currentView === index ? '#FFFFFF' : '#5F6D79')
      .fontWeight(this.currentView === index ? FontWeight.Bold : FontWeight.Regular)
      .padding({ left: 13, right: 13, top: 8, bottom: 8 })
      .backgroundColor(this.currentView === index ? '#2F6B5F' : '#E8ECEA')
      .borderRadius(17)
      .onClick(() => this.switchView(index))
  }

  @Builder
  private PublishForm() {
    Column({ space: 11 }) {
      Text('发布新通知')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#27313B')
        .width('100%')
      TextInput({ placeholder: '通知标题', text: this.title })
        .width('100%').height(40).fontSize(13).backgroundColor('#F3F5F4').borderRadius(9).padding({ left: 10, right: 10 })
        .onChange((value: string) => this.title = value)
      TextArea({ placeholder: '通知正文', text: this.content })
        .width('100%').height(90).fontSize(13).backgroundColor('#F3F5F4').borderRadius(9).padding(10)
        .onChange((value: string) => this.content = value)
      Row({ space: 6 }) {
        this.AudienceChip('全体学生', NotificationAudienceType.ALL_STUDENTS)
        this.AudienceChip('班级', NotificationAudienceType.CLASS)
        this.AudienceChip('院系', NotificationAudienceType.DEPARTMENT)
        this.AudienceChip('用户', NotificationAudienceType.USER)
      }
      if (this.audienceType !== NotificationAudienceType.ALL_STUDENTS) {
        TextInput({ placeholder: '目标 ID', text: this.targetId })
          .width('100%').height(40).fontSize(12).backgroundColor('#F3F5F4').borderRadius(9).padding({ left: 10, right: 10 })
          .onChange((value: string) => this.targetId = value)
      }
      TextInput({ placeholder: '截止时间 YYYY-MM-DD HH:mm:ss', text: this.expiresAt })
        .width('100%').height(40).fontSize(12).backgroundColor('#F3F5F4').borderRadius(9).padding({ left: 10, right: 10 })
        .onChange((value: string) => this.expiresAt = value)
      Button('确认发布')
        .width('100%').height(42).fontSize(13).backgroundColor('#2F6B5F').borderRadius(11)
        .onClick(() => this.publish())
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  private AudienceChip(text: string, type: NotificationAudienceType) {
    Text(text)
      .fontSize(10)
      .fontColor(this.audienceType === type ? '#FFFFFF' : '#566470')
      .padding({ left: 9, right: 9, top: 7, bottom: 7 })
      .backgroundColor(this.audienceType === type ? '#2F6B5F' : '#EDF1EF')
      .borderRadius(14)
      .onClick(() => this.audienceType = type)
  }

  @Builder
  private ReceivedCard(item: ReceivedNotificationInfo) {
    Column({ space: 9 }) {
      Row({ space: 10 }) {
        Text(item.isRead === 0 ? '●' : '○')
          .fontSize(12)
          .fontColor(item.isRead === 0 ? '#D48238' : '#AEB6C0')
        Column({ space: 3 }) {
          Text(item.title)
            .fontSize(16)
            .fontWeight(item.isRead === 0 ? FontWeight.Bold : FontWeight.Medium)
            .fontColor('#27313B')
            .maxLines(1)
          Text(`${item.publisherName} · ${item.publishedAt.substring(0, 16)}`)
            .fontSize(10)
            .fontColor('#89939F')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text(this.expandedId === item.id ? '⌃' : '⌄')
          .fontSize(15)
          .fontColor('#78838F')
      }
      if (this.expandedId === item.id) {
        Text(item.content)
          .fontSize(13)
          .fontColor('#55616E')
          .lineHeight(21)
          .width('100%')
        Text(`接收范围：${this.audienceLabel(item.audienceType)}`)
          .fontSize(10)
          .fontColor('#8B94A0')
          .width('100%')
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(15)
    .onClick(() => this.openNotice(item))
  }

  @Builder
  private PublishedCard(item: PublishedNotificationInfo) {
    Column({ space: 9 }) {
      Row() {
        Text(item.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#27313B').layoutWeight(1).maxLines(1)
        StatusPill({ text: statusLabel(item.status), color: statusColor(item.status), pillColor: statusBackground(item.status) })
      }.width('100%')
      Text(item.content).fontSize(12).fontColor('#65717D').maxLines(2).width('100%')
      Row() {
        Text(`${item.readCount}/${item.recipientCount} 已读 · ${this.audienceLabel(item.audienceType)}`)
          .fontSize(10).fontColor('#8A94A0')
        Blank()
        if (item.status === NotificationStatus.PUBLISHED) {
          SecondaryButton({ text: '撤回', danger: true, onTap: () => this.withdraw(item.id) })
        }
      }.width('100%')
    }
    .width('100%').padding(15).backgroundColor('#FFFFFF').borderRadius(15)
  }

  @Builder
  private ManagedCard(item: ManagedNotificationInfo) {
    Column({ space: 8 }) {
      Row() {
        Text(item.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#27313B').layoutWeight(1).maxLines(1)
        StatusPill({ text: statusLabel(item.status), color: statusColor(item.status), pillColor: statusBackground(item.status) })
      }.width('100%')
      Text(`${item.publisherName} · ${this.audienceLabel(item.audienceType)} · ${item.publishedAt.substring(0, 16)}`)
        .fontSize(10).fontColor('#89939F').width('100%')
      Text(item.content).fontSize(12).fontColor('#65717D').maxLines(2).width('100%')
      if (item.status === NotificationStatus.PUBLISHED) {
        Row() { Blank(); SecondaryButton({ text: '撤回', danger: true, onTap: () => this.withdraw(item.id) }) }.width('100%')
      }
    }
    .width('100%').padding(15).backgroundColor('#FFFFFF').borderRadius(15)
  }
}
