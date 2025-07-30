// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 0;

  @override
  Order read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Order(
      items: (fields[0] as List).cast<OrderItem>(),
      total: fields[1] as double,
      time: fields[2] as DateTime,
      orderer: fields[3] as String,
      mode: fields[8] as String,
      tableNumber: fields[4] as String?,
      status: fields[5] as String,
      paymentMethod: fields[6] as String?,
      paymentTime: fields[7] as DateTime?,
      eventDate: fields[9] as DateTime?,
      customerPhone: fields[10] as String?,
      notes: fields[11] as String?,
      amountReceived: fields[12] as double,
      change: fields[13] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.items)
      ..writeByte(1)
      ..write(obj.total)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.orderer)
      ..writeByte(4)
      ..write(obj.tableNumber)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.paymentMethod)
      ..writeByte(7)
      ..write(obj.paymentTime)
      ..writeByte(8)
      ..write(obj.mode)
      ..writeByte(9)
      ..write(obj.eventDate)
      ..writeByte(10)
      ..write(obj.customerPhone)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.amountReceived)
      ..writeByte(13)
      ..write(obj.change);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
