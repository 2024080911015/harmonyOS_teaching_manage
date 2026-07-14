@Component
export struct PageHeader {
  @Prop title: string = ''
  @Prop subtitle: string = ''

  build() {
    Column({ space: 5 }) {
      Text(this.title)
        .fontSize(27)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17202A')
      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(13)
          .fontColor('#7A8493')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@Component
export struct SectionTitle {
  @Prop title: string = ''
  @Prop action: string = ''
  onAction: () => void = (): void => {}

  build() {
    Row() {
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#202833')
      Blank()
      if (this.action.length > 0) {
        Text(this.action)
          .fontSize(13)
          .fontColor('#2F6B5F')
          .padding({ left: 10, right: 2, top: 6, bottom: 6 })
          .onClick(() => this.onAction())
      }
    }
    .width('100%')
  }
}

@Component
export struct MetricCard {
  @Prop label: string = ''
  @Prop value: string = '0'
  @Prop icon: string = '•'
  @Prop tint: string = '#2F6B5F'

  build() {
    Column({ space: 10 }) {
      Row() {
        Text(this.icon)
          .fontSize(17)
          .fontColor(this.tint)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor('#EEF6F3')
          .borderRadius(10)
        Blank()
        Text(this.value)
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1D2732')
      }
      Text(this.label)
        .fontSize(13)
        .fontColor('#778190')
        .width('100%')
    }
    .padding(14)
    .layoutWeight(1)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 12, color: '#10000000', offsetY: 3 })
    .alignItems(HorizontalAlign.Start)
  }
}

@Component
export struct StatusPill {
  @Prop text: string = ''
  @Prop color: string = '#667085'
  @Prop pillColor: string = '#EFF2F6'

  build() {
    Text(this.text)
      .fontSize(11)
      .fontColor(this.color)
      .fontWeight(FontWeight.Medium)
      .padding({ left: 9, right: 9, top: 4, bottom: 4 })
      .backgroundColor(this.pillColor)
      .borderRadius(20)
  }
}

@Component
export struct EmptyState {
  @Prop title: string = '暂无内容'
  @Prop description: string = ''
  @Prop symbol: string = '○'

  build() {
    Column({ space: 8 }) {
      Text(this.symbol)
        .fontSize(38)
        .fontColor('#A8B3BF')
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#4A5563')
      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(12)
          .fontColor('#98A1AE')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .padding({ top: 38, bottom: 38, left: 24, right: 24 })
  }
}

@Component
export struct LoadingState {
  @Prop text: string = '正在加载'

  build() {
    Row({ space: 10 }) {
      LoadingProgress()
        .width(22)
        .height(22)
        .color('#2F6B5F')
      Text(this.text)
        .fontSize(14)
        .fontColor('#7B8491')
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(32)
  }
}

@Component
export struct InlineMessage {
  @Prop text: string = ''
  @Prop error: boolean = false

  build() {
    if (this.text.length > 0) {
      Text(this.text)
        .fontSize(13)
        .fontColor(this.error ? '#B53A3A' : '#176B50')
        .width('100%')
        .padding(12)
        .backgroundColor(this.error ? '#FDEEEE' : '#EAF7F2')
        .borderRadius(10)
    }
  }
}

@Component
export struct PrimaryButton {
  @Prop text: string = '确认'
  @Prop isEnabled: boolean = true
  onTap: () => void = (): void => {}

  build() {
    Button(this.text)
      .height(44)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#FFFFFF')
      .backgroundColor(this.isEnabled ? '#2F6B5F' : '#A9B7B2')
      .borderRadius(12)
      .enabled(this.isEnabled)
      .onClick(() => this.onTap())
  }
}

@Component
export struct SecondaryButton {
  @Prop text: string = '取消'
  @Prop danger: boolean = false
  onTap: () => void = (): void => {}

  build() {
    Button(this.text)
      .height(38)
      .fontSize(13)
      .fontColor(this.danger ? '#B53A3A' : '#2F6B5F')
      .backgroundColor(this.danger ? '#FDEEEE' : '#EAF4F1')
      .borderRadius(10)
      .onClick(() => this.onTap())
  }
}
