# Установка альтернативной прошивки OpenWrt на шлюзы DGNWG05LM и ZHWG11LM

Инструкция относится только к европейской версии шлюза от xiaomi mieu01, 
с европейской вилкой, а также к версии шлюза от Aqara ZHWG11LM с китайской или 
европейской вилкой. Для версии xiaomi gateway2 с китайской вилкой 
DGNWG02LM она не подойдёт, в нём установлены другие аппаратные комплектующие.

Данная инструкция подразумевает, что у вас уже есть доступ ssh к шлюзу.
Если вы это не сделали, воспользуйтесь инструкцией

[https://4pda.ru/forum/index.php?act=findpost&pid=99314437&anchor=Spoil-99314437-1](https://4pda.ru/forum/index.php?act=findpost&pid=99314437&anchor=Spoil-99314437-1)

## Резервная копия
Сделайте резервную копию. Если вы решите вернуться на
оригинальную прошивку, для восстановления вам потребуется tar.gz с архивом 
корневой файловой системы.

```shell
tar -cvpzf /tmp/lumi_stock.tar.gz -C / . --exclude='./tmp/*' --exclude='./proc/*' --exclude='./sys/*'
```

После того, как бэкап сделается, скачайте его на локальный компьютер

```shell
scp root@*GATEWAY_IP*:/tmp/lumi_stock.tar.gz .
```

или с помощью программы WinScp в режиме `scp` (dropbear на шлюзе не поддерживает режим sftp)

Если у вас уже есть образ rootfs сделанный через dd, **всё равно сделайте архив**.
На этапе загрузки образа dd обычно возникают ошибки nand flash или ubifs. Вариант
с tar.gz лишён этих недостатков, потому что форматирует флеш перед загрузкой.

## Прошивка по воздуху

Это наиболее простой метод, который можно использовать даже через ssh.
Он не требует дополнительной пайки но работает только на оригинальной 
операционной системе. 

Убедитесь, что у вас нет лишних архивов во временной папке /tmp, потребуется место
для скачивания архивов. Также, шлюз должен быть подключён к интернету.

Запустите команду:

```shell
echo -e "GET /openlumi/owrt-installer/main/install.sh HTTP/1.0\nHost: raw.githubusercontent.com\n" | openssl s_client -quiet -connect raw.githubusercontent.com:443 2>/dev/null | sed '1,/^\r$/d' | bash
```
Данная команда завершит все процессы на шлюзе (если у вас оборвётся) сеанс ssh, 
это ожидаемое поведение. Прошивка занимает несколько минут. По окончанию прошивки,
шлюз поднимет открытую сеть OpenWrt. Если это произошло, можно сразу переходить 
к разделу ["Использование OpenWrt"](#использование-openwrt)

Репозиторий скриптов для установки https://github.com/openlumi/owrt-installer

## Если по каким-то причинам, у вас не сработал метод прошивки по воздуху, вы почти всегда можете вернуть к жизни шлюз припаяв usb и uart и прошить через mfgtools 

## Припаяйте usb + uart

Чтобы провести модификацию прошивки вам потребуется произвести
 аппаратные модификации, припаять 7 проводов к самому шлюзу
- 3 провода на usb2uart переходник (вы это делали на этапе получения рута)
- 4 провода на usb разъём или провод с usb штекером на конце.
 Достаточно припаять 4 провода, +5v, d+, d- и gnd.
 ID провод не задействуется
 Проверьте, что d+ и d- не перепутаны местами, иначе устройство не определится

![Распиновка UART и USB на шлюзе](images/gateway_pinout.jpg "Как припаивать провода")


## Прошивка

Мы подготовили архив с программой mfgtools для загрузки прощивки на шлюз,
а также саму прошивку. В архив включена программа для windows 
и консольное приложение под linux

[Версия 19.07.5 2020-12-17](files/mfgtools-19.07.5-20201217.zip)

### Подключите шлюз к компьютеру

Нужно подключить шлюз двумя кабелями к компьютеру. UART и USB.
USB на данном этапе не будет определяться в компьютере.
Чтобы подключиться к консоли шлюза, для windows используйте 
программу PuTTY и используйте COM-порт, который появился для usb2uart.
Для linux используйте любую терминальную программу, например
`picocom /dev/ttyUSB0 -b 115200` 


### Перевод в режим загрузки через USB

Для того чтобы перевести в режим прошивки, нужно при старте шлюза в 
консоли на последовательном порту прервать загрузку uboot нажатием 
любой кнопки. У вас будет 1 секунда на это. Появится приглашение для команд

    =>

Далее в командной строке uboot вам надо ввести 

    bmode usb

И нажать enter. 
После этого шлюз перейдёт в режим загрузки по usb и mfgtools сможет обновить
разделы в памяти шлюза.

![Переход в режим загрузки по USB](images/bmode_usb.png "Переход в режим загрузки по USB")

В случае если у вас Windows, вам может потребоваться установить драйвера, 
из папки Drivers.

Запускайте mfgtools.

#### Windows 
В случае windows, у вас откроется окно. Если всё припаяно правильно и драйвера
установлены верно, то в строке в программе будет написано 
HID-compliant device
![Mfgtools](images/mfgtools_win.png "Mfgtools")

Нужно нажать кнопку Start для начала прошивки. 

После окончания прошивки, когда полоска прогресса дойдёт до конца и 
станет зелёной, нужно нажать Stop. Если этого не сделать, спустя несколько 
минут программа начнёт прошивку повторно, и это приведёт к ошибке. Если такое
случилось, перезагрузите шлюз и повторите процедуру, начиная перевода
шлюза в `bmode usb`.

#### Linux

Перейдите в папку с прошивкой. Запустите консольную утилиту от суперпользователя

```shell
sudo ./mfgtoolcli -p 1
```


В псевдографическом интерфейсе будут отображаться этапы прошивки

![Mfgtools](images/mfgtools_lin.png)

При подключении шлюза и обнаружении hid устройства, программа сразу начнёт 
процесс прошивки. Если процесс не пошёл, проверьте, что устройство подключено и 
определилось в выводе команды `dmesg`


### Процесс прошивки
Следить за этапами прошивки можно также и в консоли вывода самого шлюза.
По окончанию прошивки в консоли будет выведено 

    Update Complete!

![Update complete](images/update_complete.png)

После этого можно перезагружать шлюз. Вытащите его из розетки и воткните обратно.
Иногда, шлюз виснет на финальном этапе. Если в течение 5 минут ничего не происходит, 
то скорее всего прошивка прошла удачно и можно перезагрузить шлюз.

# Не забудьте подключить антенны!

Иначе проблемы с подключением к сети обеспечены


### Использование OpenWrt

После прошивки шлюз поднимает открытую wifi сеть с именем OpenWrt.
Чтобы подключить его уже к своему роутеру, вам нужно подключиться к 
этой сети и зайти на адрес http://192.168.1.1/

По умолчанию вход на шлюз: логин root без пароля.

Перейдите в раздел Network -> Wireless

![Go to Wireless](images/owrt_menu.png)

Нажмите кнопку Scan напротив первого интерфейса radio0
Через несколько секунд вы сможете увидеть список сетей. Найдите вашу сеть 
и нажмите Join Network

![Scan](images/owrt_scan.png)

В появившемся окне отметьте галочку "Replace wireless configuration".
Ниже укажите пароль от вашей сети

![WiFi password](images/owrt_connect1.png)

На следующем экране подтвердите параметры, нажмите кнопку Save.

![WiFi password-2](images/owrt_connect2.png)

Чтобы правильно применить изменения, нужно отключить точку доступа нажав кнопку
"Disable" напротив подключения для второго интерфейса.

![Disable AP](images/owrt_disable_ap.png)

Шлюз отключит вас от точки доступа и применит изменения сети.
После прошивки меняется mac адрес шлюза, потому ip адрес тоже скорее всего
поменяется. Проверьте его в роутере или в самом шлюзе.

На шлюзе предустановлены: 
- Графический интерфейс OpenWrt LuCi на 80 порту http
- командная утилита для прошивки zigbee модуля jn5169

Не включайте на шлюзе одновременно режимы WiFi AP + Station.
Драйвер, который используется в системе не может работать в двух режимах 
одновременно.
Если вы поменяли настройки LuCi и после этого шлюз перестал подключаться к сети,
зажмите кнопку на шлюзе на 10 секунд. Он промигает жёлтым цветом 3 раза и 
перейдёт в режим начальной настройки сети, подняв точку доступа AP

### Работа с Zigbee

Модуль Zigbee может работать только с одной из систем, потому вам нужно выбрать,
какую из программ вы будете использовать. В то же время, можно использовать, 
например zigbee2mqtt для работы с zigbee и domoticz для других автоматизаций.

1. [Установка Zigbee2mqtt](./zigbee2mqtt.md)
2. [Установка Zesp32](./zesp32.md)  
3. [Установка Domoticz и настройка плагина zigate](./domoticz.md)

### Сброс на заводские настройки

Чтобы сбросить все данные на прошивке OpenWrt и вернуться на этап начальной
установки (как будто вы только что прошили шлюз), нужно зажать кнопку на 20 секунд.
Шлюз промигает красным 3 раза и вернётся к начальной настройке с поднятием точки доступа.
Будьте аккуратны со сбросом настроек, все программы и настройки будут стёрты.
Используйте его в крайнем случае, когда сброс сети и дальнейшая настройка не помогает.

### Возврат на стоковую прошивку

Для возврата на родную прошивку нужно прошить оригинальные ядро, dtb и 
файловую систему из резервной копии. Ядро и dtb одинаковые на все прошивки,
а для работы оригинального приложения xiaomi вам потребуется бекап.

[mfgtools для возврата на сток](files/mfgtools-lumi-stock.zip)

Положите свой бекап с именем `lumi_stock.tar.gz` в папку `Profiles/Linux/OS Firmware/files` 
поверх пустого файла `lumi_stock.tar.gz`

Дальше переведите шлюз в режим загрузки по usb и через mfgtools прошейте 
оригинальную прошивку. 

## gpio
благодаря @Clear_Highway и @lmahmutov

![gateway_pinout_gpio](images/gateway_pinout_gpio.png "gpio pinout")

```
opkg update
opkg install gpioctl-sysfs
opkg install kmod-spi-gpio
opkg install kmod-spi-dev
opkg install kmod-spi-gpio-custom
```

Управление
```
echo "69" > /sys/class/gpio/export
echo "70" > /sys/class/gpio/export

echo "out" > /sys/class/gpio/gpio69/direction
echo "out" > /sys/class/gpio/gpio70/direction


echo "1" > /sys/class/gpio/gpio70/value
echo "0" > /sys/class/gpio/gpio70/value
```
Номера GPIO в системе. номера контактов начинаются с нижнего на фото и продолжаются вверх. DOWN и UP
 значит куда подтяжка. Down к GND, UP - 3.3v

| № п/п | PULL | GPIO |
| :---: | :---: | :---: |
| 2 | DOWN | 69 |
| 1 | DOWN | 70 |
| 14 | DOWN | 71 |
| 15 | DOWN | 72 |
| 16 | UP | 73 |
| 4 | DOWN | 74 |
| 3 | DOWN | 75 |
| 17 | UP | 76 |
| 6 | DOWN | 77 |
| 5 | DOWN | 78 |
| 18 | DOWN | 79 |
| 20 | UP | 80 |
| 19 | DOWN | 81 |
| 8 | DOWN | 82 |
| 7 | DOWN | 83 |
| 22 | DOWN | 84 |
| 21 | DOWN | 85 |
| 10 | DOWN | 86 |
| 9 | DOWN | 87 |
| 24 | DOWN | 88 |
| 23 | DOWN | 89 |
| 12 | DOWN | 90 |
| 11 | DOWN | 91 |
| 13 | DOWN | 92 |

## Ссылки

1. Статья, которая подробно описывает изменения технические модификации: 
[Xiaomi Gateway (eu version — Lumi.gateway.mieu01 ) Hacked](https://habr.com/ru/post/494296/)
2. Сборник информации по аппаратному и програмному модингу Xiaomi Gateway [https://github.com/T-REX-XP/XiaomiGatewayHack](https://github.com/T-REX-XP/XiaomiGatewayHack)
2. Телеграм канал с обсуждением модификаций [https://t.me/xiaomi_gw_hack](https://t.me/xiaomi_gw_hack)
