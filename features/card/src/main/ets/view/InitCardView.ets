/*
 * Copyright (c) Huawei Device Co., Ltd. 2026. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/**
 * 卡片在初次加桌时，当数据没有渲染时展示龙骨图
 */
@Component
export struct InitCardView2x2 {
  build() {
    Column() {
      Row()
        .height(16)
        .width('100%')
        .backgroundColor($r('sys.color.interactive_hover'))
        .borderRadius(8)
        .margin({ bottom: 8 })

      Row()
        .height('100%')
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('sys.color.interactive_hover'))
        .borderRadius(8)
    }
  }
}

@Component
export struct InitCardView2x4_4x4 {
  private cardType: string = '';

  build() {
    Column() {
      Row()
        .height(16)
        .width('50%')
        .backgroundColor($r('sys.color.interactive_hover'))
        .borderRadius(8)
        .margin({ bottom: 8 })

      Row()
        .height('100%')
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('sys.color.interactive_hover'))
        .borderRadius(8)
    }
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .padding(12)
    .alignItems(this.cardType === 'agendaCard' ? HorizontalAlign.Start : HorizontalAlign.Center)
  }
}

@Component
export struct InitCardView4x6 {
  build() {
    Column() {
      Row()
        .height(60)
        .width('100%')
        .backgroundColor($r('sys.color.interactive_hover'))
        .borderRadius(8)
        .margin({ bottom: 12 })

      Row()
        .height('100%')
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('sys.color.interactive_hover'))
        .borderRadius(8)
    }
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .padding(12)
  }
}

@Component
export struct InitImportantCard2x2 {
  build() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.SpaceBetween,
      alignItems: ItemAlign.Center,
    }) {
      Row()
        .height(18)
        .width('80%')
        .backgroundColor($r('sys.color.interactive_hover'))
        .borderRadius('50%')
        .margin({ bottom: 4 })

      Row()
        .height('35%')
        .width('50%')
        .borderRadius(8)
        .backgroundColor($r('sys.color.interactive_hover'))

      Row()
        .height(18)
        .width('60%')
        .backgroundColor($r('sys.color.interactive_hover'))
        .borderRadius('50%')
    }
    .width('100%')
    .height('100%')
    .padding({ top: 12, bottom: 12 })
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
  }
}

@Component
export struct InitImportantCard2x4 {
  build() {
    Row() {
      Column() {
        Row()
          .height(18)
          .width('100%')
          .backgroundColor($r('sys.color.interactive_hover'))
          .borderRadius('50%')
          .margin({ bottom: 16 })
        Row()
          .height(18)
          .width('50%')
          .backgroundColor($r('sys.color.interactive_hover'))
          .borderRadius('50%')
      }
      .padding({ left: 12 })
      .alignItems(HorizontalAlign.Center)
      .width('50%')

      Column() {
        Row()
          .height('50%')
          .width('65%')
          .borderRadius(8)
          .backgroundColor($r('sys.color.interactive_hover'))
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width('50%')
      .height('100%')
    }.width('100%').height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
  }
}