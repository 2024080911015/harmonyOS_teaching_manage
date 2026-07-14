import { promptAction } from '@kit.ArkUI';

// ---------- 搜索栏组件 ----------
@Component
export struct SearchBar {
  @Prop placeholder: string = '搜索...';
  @Link searchText: string;
  onSearch: (text: string) => void = () => {};

  build() {
    Row() {
      Image($r('app.media.ic_search'))
        .width(20)
        .height(20)
        .margin({ left: 12 })
        .fillColor('#666666')

      TextInput({ placeholder: this.placeholder, text: this.searchText })
        .layoutWeight(1)
        .height(40)
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .fontSize(15)
        .onChange((value: string) => {
          this.searchText = value;
          this.onSearch(value);
        })

      if (this.searchText.length > 0) {
        Image($r('app.media.ic_close'))
          .width(18)
          .height(18)
          .margin({ right: 12 })
          .fillColor('#999999')
          .onClick(() => {
            this.searchText = '';
            this.onSearch('');
          })
      }
    }
    .width('100%')
    .height(44)
    .backgroundColor('#F5F5F5')
    .borderRadius(22)
    .padding({ left: 4, right: 4 })
  }
}

// ---------- 信息卡片组件 ----------
@Component
export struct InfoCard {
  @Prop title: string = '';
  @Prop content: string = '';
  @Prop icon: ResourceStr = $r('app.media.ic_info');
  @Prop showArrow: boolean = true;

  build() {
    Row() {
      Image(this.icon)
        .width(24)
        .height(24)
        .margin({ right: 12 })
        .fillColor('#007AFF')

      Column() {
        Text(this.title)
          .fontSize(13)
          .fontColor('#999999')
          .width('100%')
        Text(this.content)
          .fontSize(16)
          .fontColor('#1A1A1A')
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.showArrow) {
        Image($r('app.media.ic_arrow_right'))
          .width(16)
          .height(16)
          .fillColor('#CCCCCC')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: 2 })
  }
}

// ---------- 空状态组件 ----------
@Component
export struct EmptyState {
  @Prop text: string = '暂无数据';

  build() {
    Column() {
      Image($r('app.media.ic_empty'))
        .width(80)
        .height(80)
        .margin({ bottom: 16 })
        .fillColor('#CCCCCC')
      Text(this.text)
        .fontSize(14)
        .fontColor('#999999')
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}

// ---------- 标签组件 ----------
@Component
export struct StatusTag {
  @Prop text: string = '';
  @Prop type: 'default' | 'success' | 'warning' | 'danger' = 'default';

  build() {
    Text(this.text)
      .fontSize(12)
      .fontColor(this.getColor())
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .backgroundColor(this.getBgColor())
      .borderRadius(12)
  }

  private getColor(): string {
    switch (this.type) {
      case 'success': return '#34C759';
      case 'warning': return '#FF9500';
      case 'danger': return '#FF3B30';
      default: return '#007AFF';
    }
  }

  private getBgColor(): string {
    switch (this.type) {
      case 'success': return '#E8F8ED';
      case 'warning': return '#FFF5E6';
      case 'danger': return '#FFEBEB';
      default: return '#E8F2FF';
    }
  }
}

// ---------- 加载中组件 ----------
@Component
export struct LoadingView {
  build() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color('#007AFF')
      Text('加载中...')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

// ---------- 确认对话框 ----------
export function showConfirmDialog(
  title: string,
  message: string,
  onConfirm: () => void,
  onCancel?: () => void
): void {
  promptAction.showDialog({
    title: title,
    message: message,
    buttons: [
      {
        text: '取消',
        color: '#999999'
      },
      {
        text: '确定',
        color: '#007AFF'
      }
    ]
  }).then((result) => {
    if (result.index === 1) {
      onConfirm();
    } else if (onCancel) {
      onCancel();
    }
  });
}