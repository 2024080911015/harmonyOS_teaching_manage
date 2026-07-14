import { promptAction, router } from '@kit.ArkUI';
import { AppStateManager } from '../services/AppStateManager';
import { UserRole } from '../models/AppModels';

@Entry
@Component
struct LoginPage {
  @State account: string = '';
  @State password: string = '';
  private appState: AppStateManager = AppStateManager.getInstance();

  build() {
    Column() {
      // 顶部装饰
      Column() {
        Image($r('app.media.ic_class'))
          .width(80)
          .height(80)
          .margin({ top: 60, bottom: 16 })
        Text('智慧教学管理系统')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
        Text('Smart Teaching Management')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 登录表单
      Column() {
        Row() {
          Image($r('app.media.ic_class'))
            .width(20)
            .height(20)
            .fillColor('#007AFF')
          TextInput({ placeholder: '请输入账号', text: this.account })
            .layoutWeight(1)
            .height(44)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .fontSize(15)
            .onChange((value: string) => { this.account = value; })
        }
        .width('100%')
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .padding({ left: 12, right: 12 })

        Row() {
          Image($r('app.media.ic_class'))
            .width(20)
            .height(20)
            .fillColor('#007AFF')
          TextInput({ placeholder: '请输入密码', text: this.password })
            .layoutWeight(1)
            .height(44)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .fontSize(15)
            .type(InputType.Password)
            .onChange((value: string) => { this.password = value; })
        }
        .width('100%')
        .backgroundColor('#F5F5F5')
        .borderRadius(12)
        .padding({ left: 12, right: 12 })
        .margin({ top: 16 })

        // 登录按钮
        Button('登 录')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#007AFF')
          .borderRadius(12)
          .margin({ top: 30 })
          .onClick(() => {
            this.handleLogin();
          })

        // 提示文字
        Text('教师: T001/T002/T002 | 学生: 202401001/202401002\n教务处: admin001 | 学院领导: leader001/leader002')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 16 })
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ left: 40, right: 40, top: 50 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  // 通过账号识别用户角色
  private identifyUserRole(account: string): UserRole | null {
    if (account.startsWith('T')) {
      return UserRole.TEACHER;
    } else if (account.match(/^\d/)) {
      return UserRole.STUDENT;
    } else if (account.startsWith('admin')) {
      return UserRole.ACADEMIC_AFFAIRS;
    } else if (account.startsWith('leader')) {
      return UserRole.COLLEGE_LEADER;
    }
    return null;
  }

  private handleLogin(): void {
    if (!this.account.trim()) {
      promptAction.showToast({ message: '请输入账号' });
      return;
    }

    const account = this.account.trim();
    const role = this.identifyUserRole(account);
    
    if (!role) {
      promptAction.showToast({ message: '账号格式不正确，无法识别身份' });
      return;
    }

    let success = false;
    if (role === UserRole.TEACHER) {
      success = this.appState.loginAsTeacher(account);
    } else if (role === UserRole.STUDENT) {
      success = this.appState.loginAsStudent(account);
    } else if (role === UserRole.ACADEMIC_AFFAIRS) {
      success = this.appState.loginAsAcademicAffairs(account, '教务管理员');
    } else if (role === UserRole.COLLEGE_LEADER) {
      const collegeMap: Record<string, string> = {
        'leader001': '信息学院',
        'leader002': '理学院'
      };
      const college = collegeMap[account] || '信息学院';
      success = this.appState.loginAsCollegeLeader(account, '学院领导', college);
    }

    if (success) {
      promptAction.showToast({ message: '登录成功' });
      router.replaceUrl({ url: 'pages/MainPage' });
    } else {
      promptAction.showToast({ message: '账号不存在，请检查输入' });
    }
  }
}
