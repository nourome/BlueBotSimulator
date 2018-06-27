# BlueBotSimulator
OSX bluetooth simulator acting as peripheral developed using CoreBluetooth and SprikeKit

The BlueBot project consists of two parts. The first part is the laptop application that simulate an electronic robot
that communicate via bluetooth with its remote. The second part is an iOS application that behave as a bluetooth controller.


The app recieves commands from the [iOS app](https://github.com/nour7/BlueBotController) that act as central. 

Basically to to turn OSX app to a bluetooth peripheral, your need to perform these steps

1. Implement CBPeripheralManagerDelegate methods [didReceiveRead, didReceiveWrite]
2. Create a instance of CBPeripheralManager class
3. Create Service instance of CBMutableService class
4. Create characteristics instances of CBMutableCharacteristic class
5. Start advertising the service
6. Wait for read and write operation from the central
7. Notify the central when new alert occurs


![BlueBot Simulator screenshot](/screen1.png)
