import { Api } from '../api/Api'
import { UserRole } from '../api/core/ApiTypes'
import { CurrentUserInfo, LoginResult } from '../api/model/AuthModel'
import { HomePage } from './HomePage'
import { TimetablePage } from './TimetablePage'
import { CoursePage } from './CoursePage'
import { WorkflowPage } from './WorkflowPage'
import { NotificationPage } from './NotificationPage'
import { ProfilePage } from './ProfilePage'
import { AdminPage } from './AdminPage'
import { errorMessage, showToast, roleLabel } from '../utils/UiUtils'

@Entry
@Component
struct Index {
  @State booting: boolean = true
  @State loggingIn: boolean = false
  @State loggedIn: boolean = false
  @State account: string = ''
  @State password: string = ''
  @State realName: string = ''
  @State role: UserRole = UserRole.STUDENT
  @State currentTab: number = 0
  @State showPassword: boolean = false

  aboutToAppear(): void {
    Api.setUnauthorizedHandler((): void => {
      this.loggedIn = false
      this.currentTab = 0
      showToast(this.getUIContext(), { message: '登录状态已失效，请重新登录' })
    })
    this.restoreSession()
  }

  private async restoreSession(): Promise<void> {
    this.booting = true
    try {
      if (await Api.hasSession()) {
        const user: CurrentUserInfo = await Api.auth.me()
        this.realName = user.realName
        this.role = user.role
        this.account = user.account
        this.loggedIn = true
      }
    } catch (_error) {
      await Api.clearSession()
      this.loggedIn = false
    } finally {
      this.booting = false
    }
  }

  private async login(): Promise<void> {
    if (this.account.trim().length === 0 || this.password.length === 0) {
      showToast(this.getUIContext(), { message: '请输入账号和密码' })
      return
    }
    this.loggingIn = true
    try {
      const result: LoginResult = await Api.auth.login(this.account.trim(), this.password)
      this.realName = result.realName
      this.role = result.role
      this.account = result.account
      this.password = ''
      this.currentTab = 0
      this.loggedIn = true
      showToast(this.getUIContext(), { message: `欢迎回来，${result.realName}` })
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    } finally {
      this.loggingIn = false
    }
  }

  private fillDemoAccount(role: UserRole): void {
    this.role = role
    if (role === UserRole.STUDENT) {
      this.account = 'test_student_0001'
    } else if (role === UserRole.TEACHER) {
      this.account = 'test_teacher_001'
    } else if (role === UserRole.ACADEMIC_STAFF) {
      this.account = 'test_staff_001'
    } else {
      this.account = 'test_admin_01'
    }
    this.password = 'Test123456'
  }

  private isManager(): boolean {
    return this.role === UserRole.ACADEMIC_STAFF || this.role === UserRole.ADMIN
  }

  private profileIndex(): number {
    return this.isManager() ? 6 : 5
  }

  private handleLogout(): void {
    this.loggedIn = false
    this.password = ''
    this.currentTab = 0
  }

  build() {
    if (this.booting) {
      Column({ space: 16 }) {
        Text('教')
          .fontSize(34)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .width(72)
          .height(72)
          .textAlign(TextAlign.Center)
          .backgroundColor('#2F6B5F')
          .borderRadius(24)
        LoadingProgress()
          .width(28)
          .height(28)
          .color('#2F6B5F')
        Text('正在恢复教学工作台')
          .fontSize(13)
          .fontColor('#74808C')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F5F7F6')
    } else if (!this.loggedIn) {
      this.LoginView()
    } else {
      this.MainView()
    }
  }

  @Builder
  private LoginView() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Row() {
          Text('T')
            .fontSize(140)
            .fontWeight(FontWeight.Bold)
            .fontColor('#122F29')
            .opacity(0.06)
          Blank()
        }
        .width('100%')
        .padding({ left: 14, top: 14 })
        Blank()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#EAF2EF')

      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 9 }) {
            Text('教')
              .fontSize(27)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .width(58)
              .height(58)
              .textAlign(TextAlign.Center)
              .backgroundColor('#2F6B5F')
              .borderRadius(19)
            Text('教学过程管理')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#19242D')
            Text('让课程、申请和审批回到一个清晰的工作台')
              .fontSize(12)
              .fontColor('#7A8591')
              .textAlign(TextAlign.Center)
          }
          .width('100%')

          Column({ space: 13 }) {
            TextInput({ placeholder: '请输入账号', text: this.account })
              .width('100%')
              .height(48)
              .fontSize(14)
              .backgroundColor('#F3F5F4')
              .borderRadius(12)
              .padding({ left: 13, right: 13 })
              .onChange((value: string) => this.account = value)
            Stack({ alignContent: Alignment.End }) {
              TextInput({ placeholder: '请输入密码', text: this.password })
                .type(this.showPassword ? InputType.Normal : InputType.Password)
                .width('100%')
                .height(48)
                .fontSize(14)
                .backgroundColor('#F3F5F4')
                .borderRadius(12)
                .padding({ left: 13, right: 54 })
                .onChange((value: string) => this.password = value)
                .onSubmit(() => this.login())
              Text(this.showPassword ? '隐藏' : '显示')
                .fontSize(11)
                .fontColor('#2F6B5F')
                .padding({ right: 13 })
                .onClick(() => this.showPassword = !this.showPassword)
            }
            .width('100%')
            .height(48)

            Button(this.loggingIn ? '正在登录…' : '登 录')
              .width('100%')
              .height(48)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(this.loggingIn ? '#8FA9A2' : '#2F6B5F')
              .borderRadius(13)
              .enabled(!this.loggingIn)
              .onClick(() => this.login())

            Text('体验账号')
              .fontSize(11)
              .fontColor('#8B94A0')
              .width('100%')
            Row({ space: 7 }) {
              this.DemoChip('学生', UserRole.STUDENT)
              this.DemoChip('教师', UserRole.TEACHER)
              this.DemoChip('教务', UserRole.ACADEMIC_STAFF)
              this.DemoChip('管理员', UserRole.ADMIN)
            }
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(22)
          .shadow({ radius: 20, color: '#14000000', offsetY: 5 })

          Text('账号由学校统一创建 · 登录即表示同意系统使用规范')
            .fontSize(10)
            .fontColor('#8C96A1')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 64, bottom: 32 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private DemoChip(text: string, role: UserRole) {
    Text(text)
      .fontSize(10)
      .fontColor('#2F6B5F')
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .padding({ top: 8, bottom: 8 })
      .backgroundColor('#EAF4F1')
      .borderRadius(13)
      .onClick(() => this.fillDemoAccount(role))
  }

  @Builder
  private MainView() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.currentTab === 0) {
        HomePage({ role: this.role, realName: this.realName, onNavigate: (index: number) => this.currentTab = index })
      } else if (this.currentTab === 1) {
        TimetablePage()
      } else if (this.currentTab === 2) {
        CoursePage({ role: this.role })
      } else if (this.currentTab === 3) {
        WorkflowPage({ role: this.role })
      } else if (this.currentTab === 4) {
        NotificationPage({ role: this.role })
      } else if (this.isManager() && this.currentTab === 5) {
        AdminPage({ role: this.role })
      } else {
        ProfilePage({ role: this.role, onLogout: () => this.handleLogout() })
      }

      Row({ space: 1 }) {
        this.NavItem('首', '首页', 0)
        this.NavItem('表', '课表', 1)
        this.NavItem('课', '课程', 2)
        this.NavItem('办', this.isManager() ? '审批' : '办理', 3)
        this.NavItem('信', '消息', 4)
        if (this.isManager()) {
          this.NavItem('管', '管理', 5)
        }
        this.NavItem('我', '我的', this.profileIndex())
      }
      .width('100%')
      .height(72)
      .padding({ left: 6, right: 6, top: 7, bottom: 9 })
      .backgroundColor('#FCFDFC')
      .borderRadius({ topLeft: 20, topRight: 20 })
      .shadow({ radius: 18, color: '#18000000', offsetY: -2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7F6')
  }

  @Builder
  private NavItem(symbol: string, title: string, index: number) {
    Column({ space: 3 }) {
      Text(symbol)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTab === index ? '#2F6B5F' : '#9AA3AD')
      Text(title)
        .fontSize(9)
        .fontColor(this.currentTab === index ? '#2F6B5F' : '#8D97A2')
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.currentTab === index ? '#EAF4F1' : '#FCFDFC')
    .borderRadius(12)
    .onClick(() => this.currentTab = index)
  }
}
