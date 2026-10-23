# 启蒙模式词包 v2：从 68 个词扩到 243 个

产品经理审过的候选清单（daily-lesson-v2.md §6），2026-10-23 写进 `Resources/baby-path.json`（由 `scripts/add_baby_packs_v2.py` 生成，两份一致）。

## 审核时定下的
- **交通**：直接用现在的半写实图（decisions.md D10，用户定了交通工具保持半写实 3D 风格）。
- **反义词拆成两包**：
  - 反义词 1：big/small、tall/short、fast/slow、happy/sad；
  - 反义词 2：wet/dry、full/empty、loud/quiet、old/new。
  - 同一对同一天学：取到一对里的一个，就把另一个也带上，所以那天可能多学 1 个。
  - 出题时同一对互为干扰项：听 big 时，small 一定在选项里。
- **家人 2**：保持 5 个词。
- **句型**：可以按词覆盖。happy/sad 用 "I'm ___."；数字 11–20 用 "I can count to ___!"。每句都写完整，冠词和复数不靠程序拼。
- **我的感受**：去掉 funny 和 brave，补上 sleepy 和 tired。sleepy 和 tired 是易混组，出题时不会同时出现。
- **好吃的**：candy 换成 juice（5 岁的启蒙内容不主动教糖果；没有 yogurt 的图）。
- **厨房**：句型用 "Where's my ___?"。fridge 一句用 "Where's the fridge?"，因为冰箱不是「我的」。

## 规则
- 原来的 10 包顺序不变，排在最前；新包都锁着，前面的学完再按顺序打开。
- 每个词都有平涂词图（交通除外，是半写实图）和发音，单测逐个检查。

| 序 | 包名 | 词数 | 句型 | 词（例句） |
|---|---|---|---|---|
| 11 | 水果（`fruits-2`） | 9 | I like ___. | pear（I like pears.） · grape（I like grapes.） · strawberry（I like strawberries.） · cherry（I like cherries.） · lemon（I like lemons.） · mango（I like mangoes.） · peach（I like peaches.） · pineapple（I like pineapples.） · watermelon（I like watermelon.） |
| 12 | 农场动物（`farm`） | 7 | It's a ___. | hen（It's a hen.） · sheep（It's a sheep.） · goat（It's a goat.） · donkey（It's a donkey.） · mouse（It's a mouse.） · frog（It's a frog.） · bee（It's a bee.） |
| 13 | 动物园（`zoo`） | 10 | Look, a ___! | elephant（Look, an elephant!） · lion（Look, a lion!） · tiger（Look, a tiger!） · monkey（Look, a monkey!） · giraffe（Look, a giraffe!） · zebra（Look, a zebra!） · panda（Look, a panda!） · kangaroo（Look, a kangaroo!） · hippo（Look, a hippo!） · crocodile（Look, a crocodile!） |
| 14 | 海洋动物（`sea`） | 9 | I see a ___. | dolphin（I see a dolphin.） · whale（I see a whale.） · shark（I see a shark.） · octopus（I see an octopus.） · turtle（I see a turtle.） · crab（I see a crab.） · starfish（I see a starfish.） · jellyfish（I see a jellyfish.） · seal（I see a seal.） |
| 15 | 小虫和鸟（`bugs-birds`） | 7 | Where is the ___? | butterfly（Where is the butterfly?） · ant（Where is the ant?） · spider（Where is the spider?） · owl（Where is the owl?） · eagle（Where is the eagle?） · swan（Where is the swan?） · peacock（Where is the peacock?） |
| 16 | 好吃的（`food-2`） | 9 | ___, please! | cheese（Cheese, please!） · cookie（A cookie, please!） · juice（Juice, please!） · noodles（Noodles, please!） · soup（Soup, please!） · meat（Meat, please!） · pizza（Pizza, please!） · sandwich（A sandwich, please!） · honey（Honey, please!） |
| 17 | 玩具（`toys`） | 10 | I have a ___. | ball（I have a ball.） · kite（I have a kite.） · teddy（I have a teddy.） · balloon（I have a balloon.） · blocks（I have blocks.） · doll（I have a doll.） · puzzle（I have a puzzle.） · robot（I have a robot.） · drum（I have a drum.） · yoyo（I have a yoyo.） |
| 18 | 家里的东西（`home`） | 10 | This is my ___. | door（This is my door.） · window（This is my window.） · chair（This is my chair.） · table（This is my table.） · bed（This is my bed.） · lamp（This is my lamp.） · sofa（This is my sofa.） · clock（This is my clock.） · box（This is my box.） · key（This is my key.） |
| 19 | 厨房（`kitchen`） | 6 | Where's my ___? | cup（Where's my cup?） · spoon（Where's my spoon?） · fork（Where's my fork?） · plate（Where's my plate?） · bowl（Where's my bowl?） · fridge（Where's the fridge?） |
| 20 | 文具（`school-things`） | 9 | Give me the ___. | book（Give me the book.） · pen（Give me the pen.） · pencil（Give me the pencil.） · crayon（Give me the crayon.） · eraser（Give me the eraser.） · ruler（Give me the ruler.） · scissors（Give me the scissors.） · paper（Give me the paper.） · glue（Give me the glue.） |
| 21 | 交通工具（`vehicles`） | 8 | I can see a ___. | car（I can see a car.） · bus（I can see a bus.） · train（I can see a train.） · plane（I can see a plane.） · boat（I can see a boat.） · bike（I can see a bike.） · taxi（I can see a taxi.） · truck（I can see a truck.） |
| 22 | 地方（`places`） | 8 | Let's go to the ___. | school（Let's go to school.） · park（Let's go to the park.） · zoo（Let's go to the zoo.） · farm（Let's go to the farm.） · shop（Let's go to the shop.） · hospital（Let's go to the hospital.） · library（Let's go to the library.） · playground（Let's go to the playground.） |
| 23 | 大自然（`nature-2`） | 10 | Look at the ___! | tree（Look at the tree!） · flower（Look at the flower!） · leaf（Look at the leaf!） · grass（Look at the grass!） · moon（Look at the moon!） · star（Look at the star!） · snow（Look at the snow!） · sea（Look at the sea!） · mountain（Look at the mountain!） · river（Look at the river!） |
| 24 | 身体 2（`body-2`） | 6 | Touch your ___. | arm（Touch your arm.） · leg（Touch your leg.） · face（Touch your face.） · teeth（Touch your teeth.） · finger（Touch your finger.） · knee（Touch your knee.） |
| 25 | 家人 2（`family-2`） | 5 | This is my ___. | sister（This is my sister.） · brother（This is my brother.） · friend（This is my friend.） · aunt（This is my aunt.） · uncle（This is my uncle.） |
| 26 | 我会做 2（`actions-2`） | 10 | I can ___. | swim（I can swim.） · fly（I can fly.） · sit（I can sit.） · stand（I can stand.） · sing（I can sing.） · dance（I can dance.） · read（I can read.） · draw（I can draw.） · walk（I can walk.） · climb（I can climb.） |
| 27 | 我会做 3（`actions-3`） | 10 | Let's ___! | kick（Let's kick the ball!） · throw（Let's throw the ball!） · catch（Let's catch the ball!） · hug（Let's hug!） · kiss（Give me a kiss!） · smile（Let's smile!） · laugh（Let's laugh!） · cry（Don't cry!） · cook（Let's cook!） · clean（Let's clean up!） |
| 28 | 反义词 1（`opposites-1`） | 8 | It's ___. | big（It's big.） · small（It's small.） · tall（It's tall.） · short（It's short.） · fast（It's fast.） · slow（It's slow.） · happy（I'm happy.） · sad（I'm sad.） |
| 29 | 反义词 2（`opposites-2`） | 8 | It's ___. | wet（It's wet.） · dry（It's dry.） · full（It's full.） · empty（It's empty.） · loud（It's loud.） · quiet（It's quiet.） · old（It's old.） · new（It's new.） |
| 30 | 数字 11–20（`numbers-3`） | 10 | I can count to ___! | eleven（I can count to eleven!） · twelve（I can count to twelve!） · thirteen（I can count to thirteen!） · fourteen（I can count to fourteen!） · fifteen（I can count to fifteen!） · sixteen（I can count to sixteen!） · seventeen（I can count to seventeen!） · eighteen（I can count to eighteen!） · nineteen（I can count to nineteen!） · twenty（I can count to twenty!） |
| 31 | 我的感受（`feelings`） | 6 | I'm ___. | hungry（I'm hungry.） · thirsty（I'm thirsty.） · angry（I'm angry.） · afraid（I'm afraid.） · sleepy（I'm sleepy.） · tired（I'm tired.） |
