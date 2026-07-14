import { promptAction } from '@kit.ArkUI';
import { LeaveRequest, LeaveType, LeaveStatus, Attachment, Teacher } from '../models/AppModels';
import { DataService } from '../services/DataService';
import { AppStateManager } from '../services/AppStateManager';
import { User, UserRole } from '../models/DataModels';
import { EmptyState, StatusTag } from '../components/CommonComponents';

@Entry
@Component
struct TeacherLeaveApprovalPage {
  @State leaveRequests: LeaveRequest[] = [];
  @State filteredRequests: LeaveRequest[] = [];
  @State currentUser: Teacher | null = null;
  @State selectedTab: number = 0; // 0: 待审批, 1: 已处理
  @State showRejectDialog: boolean = false;
  @State rejectReason: string = '';
  @State selectedLeaveId: string = '';
  
  private dataService: DataService = DataService.getInstance();
  private appState: AppStateManager = AppStateManager.getInstance();
  
  aboutToAppear(): void {
    const user = this.appState.getCurrentUser();
    if (user) {
      this.currentUser = user as Teacher;
    }
    this.loadLeaveRequests();
  }
  
  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Image($r('app.media.ic_arrow_right'))
          .width(24)
          .height(24)
          .fillColor('#1A1A1A')
          .onClick(() => {
            // 返回上一页
          })
        
        Text('请假审批')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .margin({ left: 12 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      
      Divider().color('#F0F0F0')
      
      // Tab切换
      Row() {
        Column() {
          Text('待审批')
            .fontSize(16)
            .fontColor(this.selectedTab === 0 ? '#007AFF' : '#666666')
            .fontWeight(this.selectedTab === 0 ? FontWeight.Medium : FontWeight.Normal)
          
          if (this.selectedTab === 0) {
            Divider()
              .width(40)
              .height(3)
              .color('#007AFF')
              .margin({ top: 8 })
          }
        }
        .layoutWeight(1)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.selectedTab = 0;
          this.filterRequests();
        })
        
        Column() {
          Text('已处理')
            .fontSize(16)
            .fontColor(this.selectedTab === 1 ? '#007AFF' : '#666666')
            .fontWeight(this.selectedTab === 1 ? FontWeight.Medium : FontWeight.Normal)
          
          if (this.selectedTab === 1) {
            Divider()
              .width(40)
              .height(3)
              .color('#007AFF')
              .margin({ top: 8 })
          }
        }
        .layoutWeight(1)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.selectedTab = 1;
          this.filterRequests();
        })
      }
      .width('100%')
      .backgroundColor(Color.White)
      
      Divider().color('#F0F0F0')
      
      // 请假列表
      if (this.filteredRequests.length === 0) {
        EmptyState({ 
          text: this.selectedTab === 0 ? '暂无待审批请假' : '暂无已处理请假'
        })
      } else {
        Scroll() {
          Column() {
            ForEach(this.filteredRequests, (leave: LeaveRequest) => {
              this.LeaveApprovalCard(leave)
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  
  // 请假审批卡片组件
  @Builder
  LeaveApprovalCard(leave: LeaveRequest) {
    Column() {
      // 顶部：学生信息和请假类型
      Row() {
        Column() {
          Text(leave.studentName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1A1A1A')
          
          Text(leave.className)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        
        Blank()
        
        StatusTag({ 
          text: leave.status,
          type: this.getStatusType(leave.status)
        })
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      // 请假类型
      Row() {
        Text('请假类型：')
          .fontSize(14)
          .fontColor('#666666')
        
        Text(leave.leaveType)
          .fontSize(14)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      // 请假原因
      Row() {
        Text('请假原因：')
          .fontSize(14)
          .fontColor('#666666')
        
        Text(leave.reason)
          .fontSize(14)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      // 请假时间
      Row() {
        Text('请假时间：')
          .fontSize(14)
          .fontColor('#666666')
        
        Text(`${leave.startTime} 至 ${leave.endTime}`)
          .fontSize(14)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 8 })
      
      // 附件列表
      if (leave.attachments.length > 0) {
        Row() {
          Text('附件：')
            .fontSize(14)
            .fontColor('#666666')
          
          Column() {
            ForEach(leave.attachments, (attachment: Attachment) => {
              Text(attachment.name)
                .fontSize(14)
                .fontColor('#007AFF')
                .margin({ bottom: 4 })
            })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .margin({ bottom: 8 })
        .alignItems(VerticalAlign.Top)
      }
      
      // 审批信息（已处理）
      if (leave.status !== LeaveStatus.PENDING && leave.approverName) {
        Row() {
          Text('审批人：')
            .fontSize(14)
            .fontColor('#666666')
          
          Text(leave.approverName)
            .fontSize(14)
            .fontColor('#1A1A1A')
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 8 })
        
        if (leave.approvalTime) {
          Row() {
            Text('审批时间：')
              .fontSize(14)
              .fontColor('#666666')
            
            Text(leave.approvalTime)
              .fontSize(14)
              .fontColor('#1A1A1A')
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 8 })
        }
        
        if (leave.rejectReason) {
          Row() {
            Text('驳回原因：')
              .fontSize(14)
              .fontColor('#FF3B30')
            
            Text(leave.rejectReason)
              .fontSize(14)
              .fontColor('#FF3B30')
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 8 })
        }
      }
      
      Divider().color('#F0F0F0').margin({ top: 8, bottom: 12 })
      
      // 操作按钮（待审批状态）
      if (leave.status === LeaveStatus.PENDING) {
        Row() {
          Button('驳回')
            .height(32)
            .fontSize(14)
            .fontColor('#FF3B30')
            .backgroundColor('#FFE5E5')
            .borderRadius(4)
            .onClick(() => {
              this.selectedLeaveId = leave.id;
              this.rejectReason = '';
              this.showRejectDialog = true;
              this.showRejectDialogAction();
            })
          
          Blank()
          
          Button('通过')
            .height(32)
            .fontSize(14)
            .fontColor('#34C759')
            .backgroundColor('#E8F8ED')
            .borderRadius(4)
            .onClick(() => {
              this.approveLeave(leave.id, true);
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
  }
  
  // 获取状态类型
  private getStatusType(status: LeaveStatus): 'default' | 'success' | 'warning' | 'danger' {
    switch (status) {
      case LeaveStatus.PENDING:
        return 'warning';
      case LeaveStatus.APPROVED:
      case LeaveStatus.EXTENDED:
        return 'success';
      case LeaveStatus.REJECTED:
        return 'danger';
      case LeaveStatus.WITHDRAWN:
      case LeaveStatus.CANCELLED:
        return 'default';
      default:
        return 'default';
    }
  }
  
  // 加载请假列表
  private loadLeaveRequests(): void {
    this.leaveRequests = this.dataService.getAllLeaveRequests();
    this.filterRequests();
  }
  
  // 过滤请假列表
  private filterRequests(): void {
    if (this.selectedTab === 0) {
      this.filteredRequests = this.leaveRequests.filter(
        leave => leave.status === LeaveStatus.PENDING
      );
    } else {
      this.filteredRequests = this.leaveRequests.filter(
        leave => leave.status !== LeaveStatus.PENDING
      );
    }
  }
  
  // 审批请假
  private approveLeave(leaveId: string, isApprove: boolean): void {
    if (!this.currentUser) {
      return;
    }
    
    const success = this.dataService.approveLeaveRequest(
      leaveId,
      isApprove,
      this.currentUser.id,
      this.currentUser.name,
      isApprove ? undefined : this.rejectReason
    );
    
    if (success) {
      promptAction.showToast({ 
        message: isApprove ? '已通过' : '已驳回' 
      });
      this.loadLeaveRequests();
    } else {
      promptAction.showToast({ message: '操作失败' });
    }
  }
  
  // 显示驳回对话框
  private showRejectDialogAction(): void {
    promptAction.showDialog({
      title: '驳回请假',
      message: '请输入驳回原因',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#FF3B30' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        if (!this.rejectReason.trim()) {
          promptAction.showToast({ message: '请输入驳回原因' });
          return;
        }
        this.approveLeave(this.selectedLeaveId, false);
      }
    });
  }
}
