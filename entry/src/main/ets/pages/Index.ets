import { promptAction } from '@kit.ArkUI'
import { MyPreferences } from '../utils/PreferencesManager'
import { windowManager } from '../utils/WindowManager'

// 计分板的内容
interface contents {
  title: string
  scores: number
}

// 按键接口
interface buttonInterface {
  icon: ResourceStr
  onClick: () => void
  isPlay?: boolean
}

// 历史的数组数据
const HISTORYARR = "HISTORYARR"
const HIGHESTSCORE = "HIGHESTSCORE"

@Entry
@Component
struct Index {
  @StorageProp("topHeight") topHeight: number = 0
  // 创建保存2048内容的空数组
  @State arr: number[][] = []
  // 记录是否点击设置变量
  @State setUp: boolean = false
  // 用来保存设置的最大行数
  @State maxLine: number = 4
  // 用来保存设置的每次增加数字的数量
  @State maxAdd: number = 2
  // 记录游戏是否结束, true表示结束,false表示未结束
  @State GameState: boolean = false
  // 当前分数
  @State currentScore: number = 0
  // 最高分数
  @State highestScore: number = 0
  // 2048数组的历史记录
  historyArr: string[] = []
  // 0 无响应, 1 改变, 2 清空
  theTypeOfResponse: 0 | 1 | 2 = 0
  // 提供选择的数组
  optionalNumber: string[] = ['2', '4', '8', '16', '32']
  // 选中的数
  selected: number = 0
  // 返回的使用次数
  @State numberOfReturns: number = 1
  @State numberOfChanges: number = 1
  @State theNumberOfPurges: number = 1
  // 记录输入框内的值
  @State inputLineNum: number = 4
  @State inputAddNum: number = 2
  // 定义不同数字格子的颜色
  private bgColor: string[] = [
    "#F2E5D9", "#EEDBBB", "#FFAE70", "#FF8C4F",
    "#FF6C4B", "#FF3F0D", "#fff14a4a", "#fff33e11",
    "#ffff58ab", "#ffff51ad", "#ffe35ac0", "#ffcb6ce2",
    "#fff033d6", "#ffcf20e8", "#ffec0d93", "#fffb0000"
  ]

  aboutToAppear(): void {
    // 开始沉浸式
    windowManager.enableFullScreen(true)

    this.historyArr = MyPreferences.getData(HISTORYARR, [])

    this.highestScore = MyPreferences.getData(HIGHESTSCORE, 0)

    this.initializeTheGame()

  }

  // 上下移动的逻辑
  moveCol(up: boolean, arr: number[][]) {

    const maxLine = arr.length;

    for (let col = 0; col < maxLine; col++) {
      let colArray = arr.map(row => row[col]).filter(v => v !== 0);

      // 合并相邻相等的元素
      for (let i = colArray.length - 1; i > 0; i--) {
        if (colArray[i] === colArray[i - 1]) {
          colArray[i] *= 2;
          colArray[i - 1] = 0;
          // 计分
          this.scoring(colArray[i])
        }
      }

      colArray = colArray.filter(v => v !== 0);

      // 填充零
      const zeroArray: number[] = new Array(maxLine - colArray.length).fill(0);
      colArray = up ? colArray.concat(zeroArray) : zeroArray.concat(colArray);

      // 更新原始数组中的列
      for (let row = 0; row < maxLine; row++) {
        arr[row][col] = colArray[row];
      }
    }

    return arr;
  }

  // 左右移动的逻辑
  moveRow(toRight: boolean, arr: number[][]) {

    const maxLine = arr.length;

    for (let row = 0; row < maxLine; row++) {
      let rowArray = arr[row].filter(x => x !== 0);

      // 合并相邻相等的元素
      for (let i = rowArray.length - 1; i > 0; i--) {
        if (rowArray[i] === rowArray[i - 1]) {
          rowArray[i] *= 2;
          rowArray[i - 1] = 0;
          // 计分
          this.scoring(rowArray[i])
        }
      }

      rowArray = rowArray.filter(x => x !== 0);

      // 填充零
      const zeroArray: number[] = new Array(maxLine - rowArray.length).fill(0);
      arr[row] = toRight ? rowArray.concat(zeroArray) : zeroArray.concat(rowArray);
    }

    return arr;
  }

  // 随机往空位处添加数字, 最大数为2^5
  pushNum(num: number, arr: number[][]) {

    // 准备添加随机数进入数组
    let pushIndex: number[][] = []

    for (let i = 0; i < arr.length; i++) {
      for (let y = 0; y < arr.length; y++) {
        if (arr[i][y] === 0) {
          pushIndex.push([i, y])
        }
      }
    }

    // 随机在空位添加新的数字
    if (pushIndex.length > 0) {
      num = num > pushIndex.length ? pushIndex.length : num
      for (let i = 0; i < num; i++) {
        let temp = Math.floor(Math.random() * pushIndex.length)
        arr[pushIndex[temp][0]][pushIndex[temp][1]] = Math.pow(2, Math.floor(Math.random() * 4) + 1)
      }
    } else {
      console.log("空位已满, 暂不生成数字")
    }

    return arr
  }

  // 检查游戏是否结束
  examineGameOver(arr: number[][]) {

    const rows = arr.length;
    const cols = arr[0].length;

    // 检查是否还有空格可以移动
    for (let i = 0; i < rows; i++) {
      for (let j = 0; j < cols; j++) {
        if (arr[i][j] === 0) {
          return false; // 如果有空格可以移动，则游戏尚未结束
        }
      }
    }

    // 检查相邻的方块值是否相同
    for (let i = 0; i < rows; i++) {
      for (let j = 0; j < cols; j++) {
        // 检查上方是否有相邻方块
        if (i > 0 && arr[i][j] === arr[i - 1][j]) {
          return false;
        }
        // 检查下方是否有相邻方块
        if (i < rows - 1 && arr[i][j] === arr[i + 1][j]) {
          return false;
        }
        // 检查左侧是否有相邻方块
        if (j > 0 && arr[i][j] === arr[i][j - 1]) {
          return false;
        }
        // 检查右侧是否有相邻方块
        if (j < cols - 1 && arr[i][j] === arr[i][j + 1]) {
          return false;
        }
      }
    }

    // 如果没有空格可以移动且相邻方块值都不相同，则游戏结束
    return true;
  }

  // 进行游戏
  playTheGame(type: 1 | 2 | -1 | -2, arr: number[][]) {
    // 保存历史记录
    this.preservationHistory(arr)
    switch (type) {
      case 1:
        this.arr = this.moveRow(true, arr)
        break
      case -1:
        this.arr = this.moveRow(false, arr)
        break
      case 2:
        this.arr = this.moveCol(true, arr)
        break
      case -2:
        this.arr = this.moveCol(false, arr)
        break
      default:
        return
    }

    // 添加数字
    this.arr = this.pushNum(this.maxAdd, this.arr)
    // 检查游戏是否结束
    this.GameState = this.examineGameOver(this.arr)
  }

  // 计分
  scoring(num: number) {
    // 计算分数
    this.currentScore += num

    if (this.currentScore > this.highestScore) {
      // 判断是否是最高分
      this.highestScore = this.currentScore
      // 保存最高分
      MyPreferences.saveData(HIGHESTSCORE, this.highestScore)
    }
  }

  // 保存历史记录
  preservationHistory(arr: number[][]) {
    this.historyArr.push(JSON.stringify(arr))
    console.log("Index_this.historyArr:", JSON.stringify(this.historyArr))
    if (this.historyArr.length > 10) {
      this.historyArr = this.historyArr.slice(-10)
    }
    MyPreferences.saveData(HISTORYARR, this.historyArr)
  }

  // 清空历史记录
  clearHistory() {
    this.historyArr = []
    MyPreferences.saveData(HISTORYARR, JSON.stringify(this.historyArr))
  }

  // 自定义的弹窗
  async promptPopUp(message: string) {
    const res = await promptAction.showDialog({
      alignment: DialogAlignment.Center,
      title: "提示",
      message: message,
      buttons: [
        { text: "取消", color: "#ff8a8a8a" },
        { text: "确定", color: "#ff2c9dff" },
      ]
    })
    return res as promptAction.ShowDialogSuccessResponse
  }

  // 返回上一步
  async goBackToThePreviousStep() {
    const res = await this.promptPopUp("确定返回上一步吗？")
    if (res.index === 1) {
      if (this.historyArr.length) {
        const tempArr: number[][] = JSON.parse(this.historyArr.pop() as string)
        this.arr = tempArr
        this.numberOfReturns--
        MyPreferences.saveData(HISTORYARR, this.historyArr)
      } else {
        promptAction.showToast({ message: "还没有历史记录" })
      }
    }
  }

  // 改变数字或者清空数字
  changeOrEmpty(row: number, col: number) {
    if (this.theTypeOfResponse) {
      if (this.theTypeOfResponse === 1) {
        this.changeTheNumbers(row, col)
        this.numberOfChanges--
      } else {
        this.clearTheNumbers(row, col)
        this.theNumberOfPurges--
      }
    }
  }

  // 开启改变数字
  async changeTheArrayButtons() {
    const res = await this.promptPopUp("确定要使用魔法棒吗(可以改变任一数字)？")
    if (res.index === 1) {
      this.theTypeOfResponse = 1
    }
  }

  // 清空数字按钮
  async clearTheNumberButton() {
    const res = await this.promptPopUp("确定要使用锤子吗(可以清除任一数字)？")
    if (res.index === 1) {
      this.theTypeOfResponse = 2
    }
  }

  // 改变数字
  changeTheNumbers(row: number, col: number) {
    TextPickerDialog.show({
      range: this.optionalNumber,
      selected: this.selected,
      onAccept: (value: TextPickerResult) => {
        // 设置select为按下确定按钮时候的选中项index，这样当弹窗再次弹出时显示选中的是上一次确定的选项
        this.arr[row][col] = parseInt(value.value as string)
        this.arr = JSON.parse(JSON.stringify(this.arr))
        this.theTypeOfResponse = 0
      },
      onCancel: () => {
        console.info("TextPickerDialog:onCancel()")
      },
      onChange: (value: TextPickerResult) => {
        console.info("TextPickerDialog:onChange()" + JSON.stringify(value))
      }
    })
  }

  // 清空数字
  clearTheNumbers(row: number, col: number) {
    this.arr[row][col] = 0
    this.arr = JSON.parse(JSON.stringify(this.arr))
    this.theTypeOfResponse = 0
  }

  // 初始化游戏
  initializeTheGame() {
    if (this.arr.length === 0) {
      this.currentScore = 0
      this.numberOfReturns = 1
      this.numberOfChanges = 1
      this.theNumberOfPurges = 1
      this.clearHistory()
      for (let i = 0; i < this.maxLine; i++) {
        this.arr.push([])
        for (let y = 0; y < this.maxLine; y++) {

          if (Math.random() < 0.6) {
            this.arr[i].push(Math.pow(2, Math.floor(Math.random() * 4) + 1))
          } else {
            this.arr[i].push(0)
          }

        }
      }
    }
  }

  // 清空内容,结束游戏
  endGame() {
    this.currentScore = 0
    this.clearHistory()
    this.arr = []
  }

  @Builder
  scoreEdition($$: contents) {
    Column({ space: 5 }) {
      Text($$.title)
        .fontColor("#EED4CB")
        .fontSize(14)
        .fontWeight(500)
      Row() {
        Text(`${$$.scores}`)
          .fontWeight(500)
          .fontSize(15)
          .fontColor("#A0594E")
      }
      .width("80%")
      .aspectRatio(3.28)
      .justifyContent(FlexAlign.Center)
      .backgroundColor("#FDF5E8")
      .borderRadius(8)

    }
    .width(80)
    .aspectRatio(1.6)
    .justifyContent(FlexAlign.Center)
    .backgroundColor("#D08464")
    .borderRadius(10)
  }

  @Builder
  functionButtons($$: buttonInterface) {
    Button() {
      Column() {
        Image($$.icon)
          .width(30)
          .fillColor("#FEFEFD")
      }
      .width("100%")
      .height("100%")
      .justifyContent(FlexAlign.Center)
      .backgroundColor("#ffeaa131")
      .borderRadius(6)
    }
    .width(40)
    .aspectRatio(1)
    .type(ButtonType.Normal)
    .backgroundColor("#ffe3d7bb")
    .borderRadius(5)
    .padding(3)
    .shadow({
      radius: 3,
      color: "#c1b09e8d",
      offsetX: 3,
      offsetY: 8
    })
    .enabled($$.isPlay ?? true)
    .onClick(() => {
      $$.onClick && $$.onClick()
    })
  }

  @Builder
  titleBox() {
    Column({ space: 15 }) {
      Text("2048")
        .fontSize(30)
        .fontWeight(600)
        .fontColor("#FEFFFE")
    }
    .width(100)
    .aspectRatio(1)
    .borderRadius(8)
    .justifyContent(FlexAlign.Center)
    .backgroundColor("#EBC400")
  }

  // 设置弹窗
  @Builder
  setUpThePopUpWindow() {
    Column() {
      Row() {
        Text("最大行数: ")
          .fontSize(14)
        Slider({
          value: this.maxLine,
          min: 4,
          max: 9,
          style: SliderStyle.InSet
        }).layoutWeight(1)
          .showTips(true, this.inputLineNum.toString())
          .trackThickness(16)
          .onChange((val) => {
            this.inputLineNum = val
          })

      }

      Row() {
        Text("每次增加: ")
          .fontSize(14)
        Slider({
          value: this.maxAdd,
          min: 2,
          max: 5,
          style: SliderStyle.InSet
        }).layoutWeight(1)
          .showTips(true, this.inputAddNum.toString())
          .trackThickness(16)
          .onChange((val) => {
            this.inputAddNum = val
          })
      }

      Row({ space: 30 }) {
        Button("取 消")
          .backgroundColor("#00000000")
          .fontColor("#121212")
          .border({
            width: 1,
            color: "111"
          })
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.setUp = false
          })
        Button("确 定")
          .fontColor("#121212")
          .backgroundColor("#00000000")
          .border({
            width: 1,
            color: "111"
          })
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.setUp = false
            this.maxLine = this.inputLineNum
            this.maxAdd = this.inputAddNum
          })
      }
      .height(35)
    }
    .width(300)
    .height(180)
    .backgroundColor("#ccdfdfdf")
    .justifyContent(FlexAlign.SpaceEvenly)
    .padding(20)
    .borderRadius(15)
    .position({
      x: "50%",
      y: "40%"
    })
    .translate({
      x: "-50%",
      y: "-50%"
    })
  }

  build() {


    Stack() {
      Column()
        .width("100%")
        .height("100%")
        .blur(100)
        .linearGradient({
          angle: 135,
          colors: [["#22dab0b0", 0], ["#74c0a89a", .3], ["#87c99fa4", .7],
            ["#22d7acac", 1]]
        })
      Column({ space: 30 }) {

        // 头部栏
        Row() {
          this.titleBox()
          Column() {
            Row({ space: 10 }) {
              this.scoreEdition({ title: "分数", scores: this.currentScore })
              this.scoreEdition({ title: "最高分", scores: this.highestScore })
            }
            .width("100%")
            .alignItems(VerticalAlign.Top)
            .justifyContent(FlexAlign.End)

            Row({ space: 10 }) {

              this.functionButtons({
                icon: $r("app.media.zanting"), onClick: () => {
                  this.setUp = true
                }
              })


              Blank()
              Badge({
                count: this.numberOfReturns,
                style: {
                  badgeColor: "#cc0000"
                }
              }) {
                this.functionButtons({
                  icon: $r("app.media.fanhui"), onClick: () => {
                    this.goBackToThePreviousStep()
                  }, isPlay: Boolean(this.numberOfReturns)
                })
              }

              Badge({
                count: this.numberOfChanges,
                style: {
                  badgeColor: "#cc0000"
                }
              }) {
                this.functionButtons({
                  icon: $r("app.media.mofabang"), onClick: () => {
                    this.changeTheArrayButtons()
                  }, isPlay: Boolean(this.numberOfChanges)
                })
              }

              Badge({
                count: this.theNumberOfPurges,
                style: {
                  badgeColor: "#cc0000"
                }
              }) {
                this.functionButtons({
                  icon: $r("app.media.cuizi"), onClick: () => {
                    this.clearTheNumberButton()
                  }, isPlay: Boolean(this.theNumberOfPurges)
                })
              }
            }
            .width("100%")
            .padding({ left: 15 })
            .justifyContent(FlexAlign.End)

          }
          .height("100%")
          .layoutWeight(1)
          .padding({ top: 1, bottom: 1 })
          .justifyContent(FlexAlign.SpaceBetween)

        }
        .width("100%")
        .height(100)
        .padding({ left: 15, right: 15 })

        Column() {

          if (this.GameState) {
            Column() {
              Column({ space: 15 }) {
                Text("游戏结束")
                  .fontSize(38)
                Text("点击清空内容, 开始新游戏")
                  .fontSize(16)
              }
              .margin({ top: 100, bottom: 60 })


              Button("确定")
                .fontColor("#121212")
                .width(120)
                .backgroundColor("#00000000")
                .border({
                  width: 1,
                  color: "111"
                })
                .onClick(() => {
                  this.GameState = false
                })
            }
            .borderRadius(10)
            .width("100%")
            .height("100%")
            .backgroundColor("#ccffffff")
          } else {
            // 开始判断是否需要重新生成数组
            if (this.arr.length > 0) {
              ForEach(
                this.arr,
                (x: number[], indexX) => {
                  Row() {
                    ForEach(
                      x,
                      (y: number[], indexY) => {
                        Row() {
                          Text(y.toString() === "0" ? "" : y.toString())
                            .fontWeight(700)
                            .minFontSize(8)
                            .maxFontSize(28)

                        }
                        .margin(3)
                        .padding(3)
                        .layoutWeight(1)
                        .aspectRatio(1)
                        .backgroundColor(this.bgColor[Math.log2(this.arr[indexX][indexY])])
                        .justifyContent(FlexAlign.Center)
                        .border({
                          width: 1,
                          color: "#c6cfd2df",
                          radius: 10
                        })
                        .onClick(() => {
                          this.changeOrEmpty(indexX, indexY)
                        })

                      }
                    )
                  }
                  .width("100%")
                  .justifyContent(FlexAlign.Center)

                }
              )
            }
          }

        }
        .justifyContent(FlexAlign.Center)
        .width("100%")
        .aspectRatio(1)
        .backgroundColor("#C4AE9A")
        .borderRadius(10)
        .padding(3)
        .margin({ left: 15, right: 15 })
        .shadow({
          radius: 30,
          color: "#d0bbbbbb",
        })

        Row({ space: 30 }) {

          // 点击开始按钮后, 开始往数组内随机填充元素
          Button("点击开始")
            .onClick(() => {
              this.initializeTheGame()
            })
            .type(ButtonType.Normal)
            .padding({ left: 20, right: 20 })
            .fontColor("#111")
            .backgroundColor("#00000000")
            .border({
              width: 1,
              color: "#111",
              radius: 5
            })

          // 清空内容元素
          Button("清空内容")
            .backgroundColor("#fff83434")
            .padding({ left: 20, right: 20 })
            .onClick(() => {
              this.endGame()
            })
            .type(ButtonType.Normal)
            .border({
              width: 1,
              color: "#ff575757",
              radius: 5
            })
        }

        if (this.setUp) {
          this.setUpThePopUpWindow()
        }


      }
      .width("100%")
      .height("100%")
      .padding({ top: 80 + this.topHeight })
      .backgroundColor("#33eee")
      .gesture(
        PanGesture()
          .onActionEnd((event) => {
            if (this.arr.length) {
              if (Math.abs(event.offsetX) > Math.abs(event.offsetY)) {
                if (event.offsetX > 0) {
                  this.playTheGame(-1, this.arr)
                } else {
                  this.playTheGame(1, this.arr)
                }
              } else {
                if (event.offsetY > 0) {
                  this.playTheGame(-2, this.arr)
                } else {
                  this.playTheGame(2, this.arr)
                }
              }

            } else {
              // promptAction.showToast({message:"点击开始游戏噢"})
            }
          })
      )
    }.alignContent(Alignment.Top)

  }
}