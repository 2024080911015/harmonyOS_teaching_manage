import { Api } from '../api/Api'
import { Gender, UserRole } from '../api/core/ApiTypes'
import { TeacherRoleProfile, UserProfileInfo } from '../api/model/ProfileModel'
import { EmptyState, LoadingState, PageHeader } from '../components/UiKit'
import { errorMessage, showToast, roleLabel } from '../utils/UiUtils'

@Component
export struct ProfilePage {
  @Prop role: UserRole = UserRole.STUDENT
  onLogout: () => void = (): void => {}

  @State loading: boolean = false
  @State profile: UserProfileInfo | null = null
  @State editMode: boolean = false
  @State passwordMode: boolean = false
  @State gender: Gender = Gender.UNKNOWN
  @State phone: string = ''
  @State email: string = ''
  @State title: string = ''
  @State introduction: string = ''
  @State oldPassword: string = ''
  @State newPassword: string = ''
  @State confirmPassword: string = ''

  aboutToAppear(): void {
    this.loadProfile()
  }

  private async loadProfile(): Promise<void> {
    this.loading = true
    try {
      const result: UserProfileInfo = await Api.profile.getMyProfile()
      this.profile = result
      this.gender = result.gender
      this.phone = result.phone ?? ''
      this.email = result.email ?? ''
      if (this.role === UserRole.TEACHER && result.roleProfile !== null) {
        const teacher: TeacherRoleProfile = result.roleProfile as TeacherRoleProfile
        this.title = teacher.professionalTitle ?? ''
        this.introduction = teacher.introduction ?? ''
      }
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    } finally {
      this.loading = false
    }
  }

  private async saveProfile(): Promise<void> {
    try {
      if (this.role === UserRole.TEACHER) {
        this.profile = await Api.profile.updateMyProfile({
          gender: this.gender,
          phone: this.phone.length > 0 ? this.phone : null,
          email: this.email.length > 0 ? this.email : null,
          professionalTitle: this.title.length > 0 ? this.title : null,
          introduction: this.introduction.length > 0 ? this.introduction : null
        })
      } else {
        this.profile = await Api.profile.updateMyProfile({
          gender: this.gender,
          phone: this.phone.length > 0 ? this.phone : null,
          email: this.email.length > 0 ? this.email : null
        })
      }
      this.editMode = false
      showToast(this.getUIContext(), { message: '个人资料已更新' })
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async changePassword(): Promise<void> {
    if (this.newPassword.length < 6 || this.newPassword !== this.confirmPassword) {
      showToast(this.getUIContext(), { message: '新密码至少 6 位，且两次输入必须一致' })
      return
    }
    try {
      await Api.auth.changePassword({
        oldPassword: this.oldPassword,
        newPassword: this.newPassword,
        confirmPassword: this.confirmPassword
      })
      this.passwordMode = false
      this.oldPassword = ''
      this.newPassword = ''
      this.confirmPassword = ''
      showToast(this.getUIContext(), { message: '密码修改成功' })
    } catch (error) {
      showToast(this.getUIContext(), { message: errorMessage(error as Object) })
    }
  }

  private async logout(): Promise<void> {
    try {
      await Api.auth.logout()
    } catch (_error) {
      await Api.clearSession()
    }
    this.onLogout()
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        PageHeader({ title: '个人中心', subtitle: '账户资料与安全设置' })
        if (this.loading) {
          LoadingState({ text: '正在加载个人资料' })
        } else if (this.profile === null) {
          EmptyState({ title: '无法读取个人资料', symbol: '人' })
        } else {
          Column({ space: 14 }) {
            Text(this.profile!.realName.substring(0, 1))
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .width(72)
              .height(72)
              .textAlign(TextAlign.Center)
              .backgroundColor('#2F6B5F')
              .borderRadius(24)
            Text(this.profile!.realName)
              .fontSize(21)
              .fontWeight(FontWeight.Bold)
              .fontColor('#24303A')
            Text(`${this.profile!.account} · ${roleLabel(this.role)}`)
              .fontSize(12)
              .fontColor('#7A8591')
          }
          .width('100%')
          .padding(22)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)

          if (this.editMode) {
            this.EditForm()
          } else if (this.passwordMode) {
            this.PasswordForm()
          } else {
            Column({ space: 0 }) {
              this.InfoRow('所属院系', this.profile!.departmentName ?? '未设置')
              this.InfoRow('班级', this.profile!.className ?? '不适用')
              this.InfoRow('联系电话', this.profile!.phone ?? '未填写')
              this.InfoRow('电子邮箱', this.profile!.email ?? '未填写')
              this.InfoRow('最近登录', this.profile!.lastLoginAt ?? '暂无记录')
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
            .backgroundColor('#FFFFFF')
            .borderRadius(16)

            Button('编辑个人资料')
              .width('100%').height(44).fontSize(13).fontColor('#2F6B5F').backgroundColor('#E4F0EC').borderRadius(12)
              .onClick(() => this.editMode = true)
            Button('修改登录密码')
              .width('100%').height(44).fontSize(13).fontColor('#596673').backgroundColor('#E9ECEB').borderRadius(12)
              .onClick(() => this.passwordMode = true)
            Button('退出登录')
              .width('100%').height(44).fontSize(13).fontColor('#B53A3A').backgroundColor('#FDEEEE').borderRadius(12)
              .onClick(() => this.logout())
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
  private EditForm() {
    Column({ space: 12 }) {
      Text('编辑资料').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#27313B').width('100%')
      Row({ space: 7 }) {
        this.GenderChip('未设置', Gender.UNKNOWN)
        this.GenderChip('男', Gender.MALE)
        this.GenderChip('女', Gender.FEMALE)
      }
      this.EditInput('联系电话', this.phone, (value: string) => this.phone = value)
      this.EditInput('电子邮箱', this.email, (value: string) => this.email = value)
      if (this.role === UserRole.TEACHER) {
        this.EditInput('职称', this.title, (value: string) => this.title = value)
        TextArea({ placeholder: '个人简介', text: this.introduction })
          .width('100%').height(80).fontSize(13).backgroundColor('#F3F5F4').borderRadius(10).padding(11)
          .onChange((value: string) => this.introduction = value)
      }
      Row({ space: 8 }) {
        Button('取消').layoutWeight(1).height(42).fontSize(13).fontColor('#697581').backgroundColor('#E9ECEB').borderRadius(10)
          .onClick(() => this.editMode = false)
        Button('保存').layoutWeight(1).height(42).fontSize(13).backgroundColor('#2F6B5F').borderRadius(10)
          .onClick(() => this.saveProfile())
      }
    }
    .width('100%').padding(16).backgroundColor('#FFFFFF').borderRadius(16)
  }

  @Builder
  private PasswordForm() {
    Column({ space: 12 }) {
      Text('修改密码').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#27313B').width('100%')
      this.PasswordInput('当前密码', this.oldPassword, (value: string) => this.oldPassword = value)
      this.PasswordInput('新密码（至少 6 位）', this.newPassword, (value: string) => this.newPassword = value)
      this.PasswordInput('再次输入新密码', this.confirmPassword, (value: string) => this.confirmPassword = value)
      Row({ space: 8 }) {
        Button('取消').layoutWeight(1).height(42).fontSize(13).fontColor('#697581').backgroundColor('#E9ECEB').borderRadius(10)
          .onClick(() => this.passwordMode = false)
        Button('确认修改').layoutWeight(1).height(42).fontSize(13).backgroundColor('#2F6B5F').borderRadius(10)
          .onClick(() => this.changePassword())
      }
    }
    .width('100%').padding(16).backgroundColor('#FFFFFF').borderRadius(16)
  }

  @Builder
  private InfoRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(13).fontColor('#7A8591')
      Blank()
      Text(value).fontSize(13).fontColor('#303C47').maxLines(1)
    }
    .width('100%').height(48)
  }

  @Builder
  private GenderChip(text: string, gender: Gender) {
    Text(text)
      .fontSize(11).fontColor(this.gender === gender ? '#FFFFFF' : '#53616D')
      .padding({ left: 13, right: 13, top: 7, bottom: 7 })
      .backgroundColor(this.gender === gender ? '#2F6B5F' : '#EDF1EF').borderRadius(15)
      .onClick(() => this.gender = gender)
  }

  @Builder
  private EditInput(placeholder: string, value: string, onChange: (value: string) => void) {
    TextInput({ placeholder: placeholder, text: value })
      .width('100%').height(42).fontSize(13).backgroundColor('#F3F5F4').borderRadius(10).padding({ left: 11, right: 11 })
      .onChange((text: string) => onChange(text))
  }

  @Builder
  private PasswordInput(placeholder: string, value: string, onChange: (value: string) => void) {
    TextInput({ placeholder: placeholder, text: value })
      .type(InputType.Password)
      .width('100%').height(42).fontSize(13).backgroundColor('#F3F5F4').borderRadius(10).padding({ left: 11, right: 11 })
      .onChange((text: string) => onChange(text))
  }
}
