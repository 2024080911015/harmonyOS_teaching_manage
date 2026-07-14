import { router } from '@kit.ArkUI';
import { AppStateManager } from '../services/AppStateManager';
import { DataService } from '../services/DataService';
import { UserRole, Student, Teacher, Class, Course, LessonPlan } from '../models/AppModels';
import { SearchBar, InfoCard, EmptyState, StatusTag } from '../components/CommonComponents';

// 子页面导入
import { TeacherHomePage } from './TeacherHomePage';
import { StudentHomePage } from './StudentHomePage';
import { CourseManagementPage } from './CourseManagementPage';
import { TeacherAdjustmentPage } from './TeacherAdjustmentPage';
import { ClassroomStatusPage } from './ClassroomStatusPage';
import { CourseSelectionPage } from './CourseSelectionPage';

// 调课审批Tab包装组件
@Component
struct ApprovalTabPage {
  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('调课审批')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      
      // 提示信息
      Column() {
        Image($r('app.media.ic_class'))
          .width(80)
          .height(80)
          .margin({ bottom: 16 })
        
        Text('调课审批功能')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .margin({ bottom: 8 })
        
        Text('点击下方按钮进入调课审批页面')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ bottom: 24 })
        
        Button('进入调课审批')
          .width('60%')
          .height(44)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#007AFF')
          .borderRadius(12)
          .onClick(() => {
            router.pushUrl({ url: 'pages/ApprovalPage' });
          })
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }
}

@Entry
@Component
struct MainPage {
  @State currentTab: number = 0;
  private appState: AppStateManager = AppStateManager.getInstance();
  private dataService: DataService = DataService.getInstance();

  // Tab 标题列表
  private tabTitles: string[] = [];
  private tabIcons: ResourceStr[] = [];

  aboutToAppear(): void {
    if (this.appState.isTeacher()) {
      this.tabTitles = ['首页', '调课申请', '课程', '教室'];
      this.tabIcons = [
        $r('app.media.ic_home'),
        $r('app.media.ic_class'),
        $r('app.media.ic_course'),
        $r('app.media.ic_classroom')
      ];
    } else if (this.appState.hasApprovalPermission()) {
      // 教务处和学院领导：显示调课审批Tab
      this.tabTitles = ['调课审批', '课程', '教室'];
      this.tabIcons = [
        $r('app.media.ic_class'),
        $r('app.media.ic_course'),
        $r('app.media.ic_classroom')
      ];
    } else {
      this.tabTitles = ['首页', '选课', '课程', '教室'];
      this.tabIcons = [
        $r('app.media.ic_home'),
        $r('app.media.ic_class'),
        $r('app.media.ic_course'),
        $r('app.media.ic_classroom')
      ];
    }
  }

  build() {
    Tabs({ index: this.currentTab }) {
      // 首页/调课审批 Tab
      TabContent() {
        if (this.appState.isTeacher()) {
          TeacherHomePage()
        } else if (this.appState.hasApprovalPermission()) {
          // 教务处和学院领导：显示调课审批页面
          ApprovalTabPage()
        } else {
          StudentHomePage()
        }
      }
      .tabBar(this.TabBarBuilder(this.tabTitles[0], this.tabIcons[0], 0))

      // 学生选课 Tab（仅学生显示）
      if (!this.appState.isTeacher() && !this.appState.hasApprovalPermission()) {
        TabContent() {
          CourseSelectionPage()
        }
        .tabBar(this.TabBarBuilder(this.tabTitles[1], this.tabIcons[1], 1))
      }

      // 教师调课申请 Tab（仅教师显示）
      if (this.appState.isTeacher()) {
        TabContent() {
          TeacherAdjustmentPage()
        }
        .tabBar(this.TabBarBuilder(this.tabTitles[1], this.tabIcons[1], 1))
      }

      // 课程管理 Tab
      TabContent() {
        CourseManagementPage()
      }
      .tabBar(this.TabBarBuilder(this.tabTitles[this.appState.isTeacher() ? 2 : 2], 
                                  this.tabIcons[this.appState.isTeacher() ? 2 : 2], 
                                  this.appState.isTeacher() ? 2 : 2))

      // 教室管理 Tab
      TabContent() {
        ClassroomStatusPage()
      }
      .tabBar(this.TabBarBuilder(this.tabTitles[this.appState.isTeacher() ? 3 : 3], 
                                  this.tabIcons[this.appState.isTeacher() ? 3 : 3], 
                                  this.appState.isTeacher() ? 3 : 3))
    }
    .width('100%')
    .height('100%')
    .barMode(BarMode.Fixed)
    .onChange((index: number) => {
      this.currentTab = index;
    })
  }

  @Builder
  TabBarBuilder(title: string, icon: ResourceStr, index: number) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentTab === index ? '#007AFF' : '#999999')
      Text(title)
        .fontSize(12)
        .fontColor(this.currentTab === index ? '#007AFF' : '#999999')
        .margin({ top: 2 })
    }
    .padding({ top: 6, bottom: 6 })
  }
}
