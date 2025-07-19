# 逻辑文件
import binascii
import re
import sys
import json
# sys.path.append("GUI")

import time
from PyQt5.QtCore import QTimer, Qt
# from PyQt5.QtWidgets import *
from PyQt5.QtSerialPort import QSerialPort, QSerialPortInfo
from PyQt5.QtWidgets import QMainWindow, QListWidgetItem, QMessageBox, QTableWidgetItem
from PyQt5.QtGui import QImage, QPixmap, QTextCursor
from PyQt5.Qt import QApplication
from PyQt5.QtCore import QThread
# from PyQt5.QtWebEngineWidgets import *
from SerialPort import Ui_MainWindow

from uart import Uart


# import bitarray
# from OpenCV import OpenCVUse


# import numpy as np

class MyMainWindow(QMainWindow, Ui_MainWindow):
    version = '1.2.0'

    def __init__(self, parent=None):
        super(MyMainWindow, self).__init__(parent)
        self.setupUi(self)
        # self.read_para_json()
        # 设置实例
        # self.isOpenUART=False
        # self.create_items()
        self.uart = Uart(self)
        self.paraWidgets = dict()
        self.cb_index = 0

        self.create_signal_slot()

    # def read_para_json(self):  # 解析parameter.json
    #     try:
    #         parameter.open_json()
    #     except:
    #         QMessageBox.warning(self, '警告', '未找到正确的parameter.json')
    #         parameter.parameterList.clear()

    # 设置信号与槽
    def create_signal_slot(self):
        self.encrypt_button.clicked.connect(self.encrypt_button_clicked)
        self.decrypt_button.clicked.connect(self.decrypt_button_clicked)
        self.Com_Open_Button.clicked.connect(self.com_open_button_clicked)
        self.Com_Close_Button.clicked.connect(self.com_close_button_clicked)
        # self.Send_Button.clicked.connect(self.send_button_clicked)
        self.Com_Refresh_Button.clicked.connect(
            self.com_refresh_button_clicked)
        self.uart.readyRead.connect(self.com_receive_data)  # 接收数据
        # self.uart.connectNotify.connect(lambda x: print("New connect"))
        self.hexSending_checkBox.stateChanged.connect(self.hex_showing_clicked)
        self.hexSending_checkBox.stateChanged.connect(self.hex_sending_clicked)
        # self.About_Button.clicked.connect(self.Goto_GitHub)
        # self.checkBox_UseOpenCV.stateChanged.connect(self.on_open_cv_use_clicked)
        # self.comboBox_transpose.currentIndexChanged.connect(
        #     self.tab_piano.on_tranpose_change
        # )
        # self.textEdit_Recive.textChanged.connect(lambda: self.textEdit_Recive.moveCursor(QTextCursor.End))
        # self.textEdit_Recive.

        # Action
        self.action_uart.changed.connect(lambda: self.dockWidget_uart.setHidden(not self.action_uart.isChecked()))
        self.dockWidget_uart.visibilityChanged.connect(lambda b: self.action_uart.setChecked(b))
        self.action_exit.triggered.connect(lambda: QApplication.exit())
        self.actionAbout_Qt.triggered.connect(lambda: QMessageBox.aboutQt(self, "About Qt"))
        self.actionAboutThis.triggered.connect(self.on_about_this)
        self.action_stop.triggered.connect(lambda: self.uart.write(b'\xc10 0\0'))
        # 跳转到 GitHub 查看源代码
        # def Goto_GitHub(self):
        #     self.browser = QWebEngineView()
        #     self.browser.load(QUrl('https://github.com/Oslomayor/PyQt5-SerialPort-Stable'))
        #     self.setCentralWidget(self.browser)
    
    def encrypt_button_clicked(self):
        try:
            send_data = '0\n'
            self.uart.com_send_data(send_data, self.hexSending_checkBox.isChecked(),
                                     self.comboBox_codetype.currentText())
            send_data = self.textEdit_Send.toPlainText()
            if not send_data.endswith('\n'):
                send_data += '\n'
            time.sleep(1)
            self.uart.com_send_data(send_data, self.hexSending_checkBox.isChecked(),
                                     self.comboBox_codetype.currentText())
        except binascii.Error:
            QMessageBox.critical(self, '错误', '转换编码错误')

    def decrypt_button_clicked(self):
        try:
            send_data = '1\n'
            self.uart.com_send_data(send_data, self.hexSending_checkBox.isChecked(),
                                     self.comboBox_codetype.currentText())
            send_data = self.textEdit_Send.toPlainText()
            if not send_data.endswith('\n'):
                send_data += '\n'
            time.sleep(1)
            self.uart.com_send_data(send_data, self.hexSending_checkBox.isChecked(),
                                     self.comboBox_codetype.currentText())
        except binascii.Error:
            QMessageBox.critical(self, '错误', '转换编码错误')

    def com_refresh_button_clicked(self):
        self.Com_Name_Combo.clear()
        com = QSerialPort()
        com_list = QSerialPortInfo.availablePorts()
        for info in com_list:
            com.setPort(info)
            if com.open(QSerialPort.ReadWrite):
                self.Com_Name_Combo.addItem(info.portName())
                com.close()

    # 16进制显示按下
    def hex_showing_clicked(self):
        if self.hexShowing_checkBox.isChecked():
            # 接收区换行
            self.textEdit_Recive.insertPlainText('\n')

    # 16进制发送按下
    def hex_sending_clicked(self):
        if self.hexSending_checkBox.isChecked():
            pass

    # 发送按钮按下
    # def send_button_clicked(self):
    #     try:
    #         send_data = self.textEdit_Send.toPlainText()

    #         # 确保每次发送的文本末尾加上换行符（如果没有的话）
    #         if not send_data.endswith('\n'):
    #             send_data += '\n'

    #         self.uart.com_send_data(send_data, self.hexSending_checkBox.isChecked(),
    #                                  self.comboBox_codetype.currentText())
    #     except binascii.Error:
    #         QMessageBox.critical(self, '错误', '转换编码错误')

    # 串口打开按钮按下
    def com_open_button_clicked(self):
        # com Open Code here #
        com_name = self.Com_Name_Combo.currentText()
        com_baud = int(self.Com_Baud_Combo.currentText())
        self.uart.setPortName(com_name)
        self.uart.setBaudRate(com_baud)
        self.uart.setParity(self.uart.comParity[self.comboBox_parity.currentIndex()])
        self.uart.setDataBits(int(self.comboBox_data.currentText()))
        self.uart.setStopBits(int(self.comboBox_stop.currentText()))

        try:
            if not self.uart.open(QSerialPort.ReadWrite):
                QMessageBox.critical(self, '严重错误', '串口打开失败')
                return
        except:
            QMessageBox.critical(self, '严重错误', '串口打开失败')
            return
        # self.Com_Close_Button.setEnabled(True)
        # self.Com_Open_Button.setEnabled(False)
        # self.Com_Refresh_Button.setEnabled(False)
        # self.Com_Name_Combo.setEnabled(False)
        # self.Com_Baud_Combo.setEnabled(False)

        self.Com_isOpenOrNot_Label.setText('  已打开')


    def com_close_button_clicked(self):
        self.uart.close()
        # self.Com_Close_Button.setEnabled(False)
        # self.Com_Open_Button.setEnabled(True)
        # self.Com_Refresh_Button.setEnabled(True)
        # self.Com_Name_Combo.setEnabled(True)
        # self.Com_Baud_Combo.setEnabled(True)

        self.set_widgets_enabled(True)
        self.Com_isOpenOrNot_Label.setText('  已关闭')

    def com_receive_data(self):
        tab_widget_current_index = self.tabWidget.currentIndex()
        if tab_widget_current_index == 0:  # 收发模式
            try:
                msg = self.uart.com_receive_normal(self.hexShowing_checkBox.isChecked(),
                                                   self.comboBox_codetype.currentText())
                # self.textEdit_Recive.append(msg)

                self.textEdit_Recive.moveCursor(QTextCursor.End)
                self.textEdit_Recive.insertPlainText(msg)
                # self.textEdit_Recive.update()
                # self.textEdit_Recive.insertPlainText(msg)

            except:
                QMessageBox.critical(self, '严重错误', '串口接收数据错误')
        elif tab_widget_current_index == 1:  # 图像模式
            ret = self.uart.com_receive_image(self.cb_index, self.label_img.extra_bytes_len)
            if ret is not None:
                img, extra_bytes = ret
                self.label_img.extra_data = extra_bytes
                self.label_img.setPixmap(img)
        # elif tab_widget_current_index == 2:  # 调参模式 且 已发送 hyxr
        #     self.uart.com_receive_para()
        else:
            self.uart.com_receive_standard()  # 标准模式读取

    def send_read_mcu(self):
        if self.uart.isOpen():
            start = b'\xb3\x00'
            self.uart.write(start)
        #     self.uart.write(b'hyxr')
        #     self.ready_to_get_paras = True

    # def on_open_cv_use_clicked(self):
    #     if self.checkBox_UseOpenCV.isChecked():
    #         OpenCVUse.init()
    #         # self.test()
    #     else:
    #         OpenCVUse.close()

    def on_show_grid_changed(self, a0: int):
        # print(a0)
        if a0 == 0:  # 取消勾选
            self.label_img.enable_grid = False
            self.label_img.repaint()
        else:  # 勾选
            self.label_img.enable_grid = True
            self.label_img.calculate_grid_points()
            self.label_img.repaint()

    def save_img(self):
        # pass
        s = str(int(time.time()))
        self.label_img.qpix.save("./output/" + s + ".png", "png", -1)
        # QMessageBox.warning(self, '成功', '保存成功')
        QMessageBox.information(self, '成功', '保存成功')

    def on_clear_dict(self):
        self.uart.wave_paras.clear()
        self.uart.watch_paras.clear()
        self.tableWidget_para.clear()
        self.tableWidget_para.setRowCount(0)
        self.graphicsView.clear()

    def on_about_this(self):
        QMessageBox.about(self, "多功能串口调试助手", "版本：%s\n作者：侯宇轩" % self.version)

    def update_standard_gui(self, index_receive):
        # if index_receive == self.tabWidget_other.currentIndex():  # 标准（其他）模式下的tabwigdget
        index = self.tabWidget_other.currentIndex()
        if index == 0 and index_receive in (0, 2):  # 读参数模式
            # self.tableWidget_para.setRowCount(len(self.uart.watch_paras)+len(self.uart.wave_paras))
            for key in self.uart.watch_paras:
                lis = self.tableWidget_para.findItems(key, Qt.MatchExactly)
                value = self.uart.watch_paras[key]
                if len(lis) > 0 and lis[0].column() == 0:  # 有该元素
                    row = lis[0].row()
                    self.tableWidget_para.item(row, 1).setText(value)
                else:  # 没有该元素
                    length = self.tableWidget_para.rowCount()
                    self.tableWidget_para.insertRow(length)
                    self.tableWidget_para.setItem(length, 0, QTableWidgetItem(key))
                    self.tableWidget_para.setItem(length, 1, QTableWidgetItem(value))
                    self.tableWidget_para.sortByColumn(0, 0)

            for key in self.uart.wave_paras:
                lis = self.tableWidget_para.findItems(key, Qt.MatchExactly)
                value = self.uart.wave_paras[key]
                if len(lis) > 0 and lis[0].column() == 0:  # 有该元素
                    row = lis[0].row()
                    self.tableWidget_para.item(row, 1).setText(value)
                else:  # 没有该元素
                    length = self.tableWidget_para.rowCount()
                    self.tableWidget_para.insertRow(length)
                    self.tableWidget_para.setItem(length, 0, QTableWidgetItem(key))
                    self.tableWidget_para.setItem(length, 1, QTableWidgetItem(value))
                    self.tableWidget_para.sortByColumn(0, 0)

        elif index == 1 and index_receive == 1:  # 改参数模式
            # item.paras.value = value
            error_keys = list()
            for key in self.uart.change_paras:
                value_str = self.uart.change_paras[key]
                try:
                    pos, va = value_str.split(',', 1)
                except:
                    print('read change para error')
                    error_keys.append(key)
                    # self.uart.change_paras.pop(key)
                    pass
                else:  # 正常解析
                    if key in self.paraWidgets:
                        self.paraWidgets[key].para_value.setText(va)
                    else:
                        para_widget = Widget_ParaItem(key, pos, va, self.uart)
                        self.paraWidgets[key] = para_widget
                        para_list_widget_item = QListWidgetItem(self.listWidget_para)
                        self.listWidget_para.addItem(para_list_widget_item)
                        self.listWidget_para.setItemWidget(
                            para_list_widget_item, para_widget)
                        size = para_widget.minimumSizeHint()
                        para_list_widget_item.setSizeHint(size)
                # #
                # index_2 = int(key)
                # if index_2 >= len(self.paraWidgets):
                #
                #     # self.listWidget_para.addItem()
                #     self.paraWidgets.append(para_widget)
                #     para_listWidgetItem = QListWidgetItem(self.listWidget_para)
                #     self.listWidget_para.addItem(para_listWidgetItem)
                #     self.listWidget_para.setItemWidget(
                #         para_listWidgetItem, para_widget)
                #     size = para_widget.minimumSizeHint()
                #     para_listWidgetItem.setSizeHint(size)
                # self.paraWidgets[index_2].index = key
                # self.paraWidgets[index_2].para_value.setText(self.uart.change_paras[key])
                # self.paraWidgets[index_2].paras.value = self.uart.change_paras[key]
            for k in error_keys:
                del self.uart.change_paras[k]
        elif index == 2 and index_receive == 2:  # 波形模式
            # self.graphicsView.add_new_data(self.uart.wave_paras)
            if not self.wave_thread.dic_queue.full():
                self.wave_thread.dic_queue.put(self.uart.wave_paras)
        elif index_receive == -1:  # 修改参数成功
            # ss = self.uart.standard_rx_data[1:].data().decode(errors='ignore')
            # self.uart.standard_rx_data.clear()
            if len(self.uart.list_of_msg) > 0:
                ss = self.uart.list_of_msg[0].data().decode(errors='ignore')
                QMessageBox.information(self, '成功', '成功修改参数为：' + ss)

    # def clear_read_buffer(self):
    #     pass
    #
    # def clear_write_buffer(self):
    #     pass

    # def resizeEvent(self, a0: QtGui.QResizeEvent):
    #     #super(MyMainWindow, self).resizeEvent(a0)
    #     size = self.label_img.size()
    #     self.label_img.setPixmap(QPixmap.fromImage(self.img).scaled(size, Qt.KeepAspectRatio))

    # def paintEvent(self, a0: QtGui.QPaintEvent):
    #     # super(MyMainWindow, self).paintEvent(a0)
    #
    #     painter = QPainter(self.label_img)
    #     painter.drawPixmap(0, 0, self.label_img.width(),
    #                        self.label_img.height(), QPixmap.fromImage(self.img))
    # def on_action_uart_change(self):

    def test(self):
        self.tabWidget.setCurrentIndex(1)
        self.imgWidth = 80
        self.imgHeight = 60
        testbytes = b'\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff' * \
                    16 + b'\xff\xff\xff\xff\xff\xff\xff\xff\xff\x0f' * 44
        # testbytes = (b'\x00\x00' * 8 + b'\xfe\x91\x01\x01\x01\x01\xff\xff' * 8) * \
        #             16 + b'\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00' * 8 * 44
        # imgbits = bitarray.bitarray(endian='big')
        # imgbits.frombytes(testbytes)
        # print(self.imgrxData)
        # imgbytes = imgbits.unpack(zero=b'\x01', one=b'\x00')
        # print(imgbytes)
        # self.label_img.setScaledContents(True)
        # self.label_img.setAlignment(Qt.AlignCenter)
        # if self.checkBox_UseOpenCV.isChecked():
        #     OpenCVUse.process(imgbytes, self.imgHeight, self.imgWidth)

        # self.img = QImage(testbytes, self.imgWidth,
        #                 self.imgHeight, QImage.Format_Mono)
        # self.img = QBitmap.fromData(QSize(self.imgWidth, self.imgHeight, ), testbytes, QImage.Format_Mono)
        testbytes = bytearray(testbytes)
        testbytes = bytes([255 if int.from_bytes(b, 'little') > 0 else 0 for b in testbytes])
        self.img = QPixmap.fromImage(QImage(testbytes, self.imgWidth, self.imgHeight, QImage.Format_Grayscale8))

        # self.img=QBitmap.fromData(QSize(self.imgWidth,self.imgHeight,),testbytes,QImage.Format_Indexed8)
        # self.img=self.img.convertToFormat(QImage.Format_Grayscale8)
        # print(self.img.height())
        # print(self.img.width())
        # print(self.img.dotsPerMeterY())
        # print(self.img.dotsPerMeterX())
        # self.img=QPixmap.loadFromData()
        # self.label_img.setScaledContents(False)
        # size = self.label_img.size()
        self.label_img.setPixmap(self.img)

    # def keyPressEvent(self, a0: QtGui.QKeyEvent):
    #     if a0.key() == Qt.Key_P:
    #         print("Key press")
    #         # QMessageBox("critical","haha")


def main():
    app = QApplication(sys.argv)
    my_win = MyMainWindow()
    # mywin
    # my_win.test()
    my_win.show()
    # myWin.showFullScreen()

    sys.exit(app.exec_())


if __name__ == '__main__':
    main()