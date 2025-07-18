// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: non_constant_identifier_names

part of 'localDatabase.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class CartProduct extends DataClass implements Insertable<CartProduct> {
  final String id;
  final String? category_id;
  final String name;
  final String photo;
  final String price;
  final String? discountPrice;
  final String? item;
  final String? groceryWeight;
  final String? groceryUnit;
  final String vendorID;
  late int quantity;
  late final String? extras_price;
  late dynamic extras;
  late dynamic variant_info;
  final String? packingcharges;

  CartProduct({
    required this.id,
    required this.category_id,
    required this.name,
    required this.photo,
    required this.price,
    this.discountPrice = "",
    this.item = "",
    this.groceryUnit = "",
    this.groceryWeight = "",
    required this.vendorID,
    required this.quantity,
    this.extras_price,
    this.extras,
    this.variant_info,
    this.packingcharges,
  });

  factory CartProduct.fromData(
    Map<String, dynamic> data,
    GeneratedDatabase db, {
    String? prefix,
  }) {
    final effectivePrefix = prefix ?? '';
    return CartProduct(
      id:
          const StringType().mapFromDatabaseResponse(
            data['${effectivePrefix}id'],
          )!,
      category_id:
          const StringType().mapFromDatabaseResponse(
            data['${effectivePrefix}category_id'],
          )!,
      name:
          const StringType().mapFromDatabaseResponse(
            data['${effectivePrefix}name'],
          )!,
      photo:
          const StringType().mapFromDatabaseResponse(
            data['${effectivePrefix}photo'],
          )!,
      price:
          const StringType().mapFromDatabaseResponse(
            data['${effectivePrefix}price'],
          )!,
      discountPrice: const StringType().mapFromDatabaseResponse(
        data['${effectivePrefix}discount_price'],
      ),
      item: const StringType().mapFromDatabaseResponse(
        data['${effectivePrefix}item'],
      ),
      groceryWeight: const StringType().mapFromDatabaseResponse(
        data['${effectivePrefix}groceryWeight'],
      ),
      groceryUnit: const StringType().mapFromDatabaseResponse(
        data['${effectivePrefix}groceryUnit'],
      ),
      vendorID:
          const StringType().mapFromDatabaseResponse(
            data['${effectivePrefix}vendor_i_d'],
          )!,
      quantity:
          const IntType().mapFromDatabaseResponse(
            data['${effectivePrefix}quantity'],
          )!,
      extras_price: const StringType().mapFromDatabaseResponse(
        data['${effectivePrefix}extras_price'],
      ),
      extras: const StringType().mapFromDatabaseResponse(
        data['${effectivePrefix}extras'],
      ),
      variant_info: const StringType().mapFromDatabaseResponse(
        data['${effectivePrefix}variant_info'],
      ),
      packingcharges: const StringType().mapFromDatabaseResponse(
        data['${effectivePrefix}packingcharges'],
      ),
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(category_id!);
    map['name'] = Variable<String>(name);
    map['photo'] = Variable<String>(photo);
    map['price'] = Variable<String>(price);

    if (!nullToAbsent || discountPrice != null) {
      map['discount_price'] = Variable<String?>(discountPrice);
    }
    if (!nullToAbsent || item != null) {
      map['item'] = Variable<String?>(item);
    }
    if (!nullToAbsent || groceryUnit != null) {
      map['groceryUnit'] = Variable<String?>(groceryUnit);
    }
    if (!nullToAbsent || groceryWeight != null) {
      map['groceryWeight'] = Variable<String?>(groceryWeight);
    }
    map['vendor_i_d'] = Variable<String>(vendorID);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || extras_price != null) {
      map['extras_price'] = Variable<String?>(extras_price);
    }
    if (!nullToAbsent || extras != null) {
      map['extras'] = Variable<String?>(jsonEncode(extras));
    }
    if (!nullToAbsent || variant_info != null) {
      map['variant_info'] = Variable<String?>(jsonEncode(variant_info));
    }
    if (!nullToAbsent || packingcharges != null) {
      map['packingcharges'] = Variable<String?>(packingcharges);
    }
    return map;
  }

  CartProductsCompanion toCompanion(bool nullToAbsent) {
    return CartProductsCompanion(
      id: Value(id),
      category_id: Value(category_id!),
      name: Value(name),
      photo: Value(photo),
      price: Value(price),
      discountPrice:
          discountPrice == null && nullToAbsent
              ? const Value.absent()
              : Value(discountPrice),
      item: item == null && nullToAbsent ? const Value.absent() : Value(item),
      groceryUnit:
          groceryUnit == null && nullToAbsent
              ? const Value.absent()
              : Value(groceryUnit),
      groceryWeight:
          groceryWeight == null && nullToAbsent
              ? const Value.absent()
              : Value(groceryWeight),
      vendorID: Value(vendorID),
      quantity: Value(quantity),
      extras_price:
          extras_price == null && nullToAbsent
              ? const Value.absent()
              : Value(extras_price),
      extras:
          extras == null && nullToAbsent ? const Value.absent() : Value(extras),
      variant_info:
          variant_info == null && nullToAbsent
              ? const Value.absent()
              : Value(variant_info),
      packingcharges:
          packingcharges == null && nullToAbsent
              ? const Value.absent()
              : Value(packingcharges ?? ''),
    );
  }

  factory CartProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    dynamic extrasVal;
    if (json['extras'] == null) {
      extrasVal = List<String>.empty();
    } else {
      if (json['extras'] is String) {
        if (json['extras'] == '[]') {
          extrasVal = List<String>.empty();
        } else {
          String extraDecode = json['extras']
              .toString()
              .replaceAll("[", "")
              .replaceAll("]", "")
              .replaceAll("\"", "");
          if (extraDecode.contains(",")) {
            extrasVal = extraDecode.split(",");
          } else {
            extrasVal = [extraDecode];
          }
        }
      }
      if (json['extras'] is List) {
        extrasVal = json['extras'].cast<String>();
      }
    }

    return CartProduct(
      id: serializer.fromJson<String>(json['id']),
      category_id: serializer.fromJson<String>(json['category_id'] ?? ''),
      name: serializer.fromJson<String>(json['name']),
      photo: serializer.fromJson<String>(json['photo']),
      price: serializer.fromJson<String>(json['price']),
      discountPrice: serializer.fromJson<String?>(json['discountPrice']),
      item: serializer.fromJson<String?>(json['item']),
      groceryUnit: serializer.fromJson<String?>(json['groceryUnit']),
      groceryWeight: serializer.fromJson<String?>(json['groceryWeight']),
      vendorID: serializer.fromJson<String>(json['vendorID']),
      quantity: serializer.fromJson<int>(json['quantity']),
      extras_price: serializer.fromJson<String?>(json['extras_price']),
      extras: serializer.fromJson<List<dynamic>?>(extrasVal),
      variant_info:
          json['variant_info'] != null
              ? serializer.fromJson<VariantInfo>(
                (json.containsKey('variant_info') &&
                        json['variant_info'] != null)
                    ? VariantInfo.fromJson(json['variant_info'])
                    : null,
              )
              : null,
      packingcharges: serializer.fromJson<String?>(json['packingcharges']),
    );
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    if (extras == null) {
      extras = List<String>.empty();
    } else {
      if (extras is String) {
        extras = extras.toString().replaceAll("\"", "");
        if (extras == '[]' || extras.toString().isEmpty) {
          extras = List<String>.empty();
        } else {
          extras = extras
              .toString()
              .replaceAll("[", "")
              .replaceAll("]", "")
              .replaceAll("\"", "");
          if (extras.toString().contains(",")) {
            extras = extras.toString().split(",");
          } else {
            extras = [(extras.toString())];
          }
        }
      }
      if (extras is List) {
        if ((extras as List).isEmpty) {
          extras = List<String>.empty();
        } else if (extras[0] == "[]") {
          extras = List<String>.empty();
        } else {
          extras = extras;
        }
      }
    }
    return <String, dynamic>{
      'id': serializer.toJson<String>(id.split('~').first),
      'category_id': serializer.toJson<String>(category_id!),
      'name': serializer.toJson<String>(name),
      'photo': serializer.toJson<String>(photo),
      'price': serializer.toJson<String>(price),
      'discountPrice': serializer.toJson<String?>(discountPrice),
      'item': serializer.toJson<String?>(item),
      'groceryWeight': serializer.toJson<String?>(groceryWeight),
      'groceryUnit': serializer.toJson<String?>(groceryUnit),
      'vendorID': serializer.toJson<String>(vendorID),
      'quantity': serializer.toJson<int>(quantity),
      'extras_price': serializer.toJson<String?>(extras_price),
      'extras': serializer.toJson<List<dynamic>>(extras),
      'variant_info':
          variant_info != null
              ? serializer.toJson<Map<String, dynamic>>(
                VariantInfo.fromJson(jsonDecode(variant_info)).toJson(),
              )
              : null,
      'packingcharges': serializer.toJson<String?>(packingcharges),
    };
  }

  CartProduct copyWith({
    String? id,
    String? category_id,
    String? name,
    String? photo,
    String? price,
    String? packingcharges,
    String? discountPrice,
    String? item,
    String? groceryUnit,
    String? groceryWeight,
    String? vendorID,
    int? quantity,
    String? extras_price,
    String? extras,
    String? variant_info,
  }) => CartProduct(
    id: id ?? this.id,
    category_id: category_id ?? this.category_id,
    name: name ?? this.name,
    photo: photo ?? this.photo,
    price: price ?? this.price,
    discountPrice: discountPrice ?? this.discountPrice,
    item: item ?? this.item,
    groceryWeight: groceryWeight ?? this.groceryWeight,
    groceryUnit: groceryUnit ?? this.groceryUnit,
    vendorID: vendorID ?? this.vendorID,
    quantity: quantity ?? this.quantity,
    extras_price: extras_price ?? this.extras_price,
    extras: extras ?? this.extras,
    variant_info: variant_info ?? this.variant_info.toJson(),
    packingcharges: packingcharges ?? this.packingcharges,
  );

  @override
  String toString() {
    return (StringBuffer('CartProduct(')
          ..write('id: $id, ')
          ..write('category_id: $category_id, ')
          ..write('name: $name, ')
          ..write('photo: $photo, ')
          ..write('price: $price, ')
          ..write('discountPrice: $discountPrice, ')
          ..write('item: $item, ')
          ..write('groceryUnit: $groceryUnit, ')
          ..write('groceryWeight: $groceryWeight, ')
          ..write('vendorID: $vendorID, ')
          ..write('quantity: $quantity, ')
          ..write('extras_price: $extras_price, ')
          ..write('extras: $extras, ')
          ..write('variant_info: $variant_info, ')
          ..write('packingcharges: $packingcharges, ')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category_id,
    name,
    photo,
    price,
    discountPrice,
    item,
    groceryWeight,
    groceryUnit,
    vendorID,
    quantity,
    extras_price,
    extras,
    variant_info,
    packingcharges,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartProduct &&
          other.id == this.id &&
          other.category_id == this.category_id &&
          other.name == this.name &&
          other.photo == this.photo &&
          other.price == this.price &&
          other.discountPrice == this.discountPrice &&
          other.item == this.item &&
          other.groceryUnit == this.groceryUnit &&
          other.groceryWeight == this.groceryWeight &&
          other.vendorID == this.vendorID &&
          other.quantity == this.quantity &&
          other.extras_price == this.extras_price &&
          other.extras == this.extras &&
          other.variant_info == this.variant_info &&
          other.packingcharges == this.packingcharges);
}

class CartProductsCompanion extends UpdateCompanion<CartProduct> {
  final Value<String> id;
  final Value<String> category_id;
  final Value<String> name;
  final Value<String> photo;
  final Value<String> price;
  final Value<String> packingcharges;
  final Value<String?> discountPrice;
  final Value<String?> item;
  final Value<String?> groceryWeight;
  final Value<String?> groceryUnit;
  final Value<String> vendorID;
  final Value<int> quantity;
  final Value<String?> extras_price;
  final Value<String?> extras;
  final Value<String?> variant_info;

  const CartProductsCompanion({
    this.id = const Value.absent(),
    this.category_id = const Value.absent(),
    this.name = const Value.absent(),
    this.photo = const Value.absent(),
    this.price = const Value.absent(),
    this.packingcharges = const Value.absent(),
    this.discountPrice = const Value.absent(),
    this.item = const Value.absent(),
    this.groceryWeight = const Value.absent(),
    this.groceryUnit = const Value.absent(),
    this.vendorID = const Value.absent(),
    this.quantity = const Value.absent(),
    this.extras_price = const Value.absent(),
    this.extras = const Value.absent(),
    this.variant_info = const Value.absent(),
  });

  CartProductsCompanion.insert({
    required String id,
    required String category_id,
    required String name,
    required String photo,
    required String price,
    required String packingcharges,
    this.discountPrice = const Value.absent(),
    this.item = const Value.absent(),
    this.groceryWeight = const Value.absent(),
    this.groceryUnit = const Value.absent(),
    required String vendorID,
    required int quantity,
    this.extras_price = const Value.absent(),
    this.extras = const Value.absent(),
    this.variant_info = const Value.absent(),
  }) : id = Value(id),
       category_id = Value(category_id),
       name = Value(name),
       photo = Value(photo),
       price = Value(price),
       packingcharges = Value(packingcharges),
       vendorID = Value(vendorID),
       quantity = Value(quantity);

  static Insertable<CartProduct> custom({
    Expression<String>? id,
    Expression<String>? category_id,
    Expression<String>? name,
    Expression<String>? photo,
    Expression<String>? price,
    Expression<String>? packingcharges,
    Expression<String?>? discountPrice,
    Expression<String?>? item,
    Expression<String?>? groceryUnit,
    Expression<String?>? groceryWeight,
    Expression<String>? vendorID,
    Expression<int>? quantity,
    Expression<String?>? extras_price,
    Expression<String?>? extras,
    Expression<String?>? variant_info,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category_id != null) 'category_id': category_id,
      if (name != null) 'name': name,
      if (photo != null) 'photo': photo,
      if (price != null) 'price': price,
      if (packingcharges != null) 'packingcharges': packingcharges,
      if (discountPrice != null) 'discount_price': discountPrice,
      if (groceryWeight != null) 'groceryWeight': groceryWeight,
      if (groceryUnit != null) 'discount_price': groceryUnit,
      if (item != null) 'item': item,
      if (vendorID != null) 'vendor_i_d': vendorID,
      if (quantity != null) 'quantity': quantity,
      if (extras_price != null) 'extras_price': extras_price,
      if (extras != null) 'extras': extras,
      if (variant_info != null) 'variant_info': variant_info,
    });
  }

  CartProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? category_id,
    Value<String>? name,
    Value<String>? photo,
    Value<String>? price,
    Value<String>? packingcharges,
    Value<String?>? discountPrice,
    Value<String?>? item,
    Value<String?>? groceryUnit,
    Value<String?>? groceryWeight,
    Value<String>? vendorID,
    Value<int>? quantity,
    Value<String?>? extras_price,
    Value<String?>? extras,
    Value<String?>? variant_info,
  }) {
    return CartProductsCompanion(
      id: id ?? this.id,
      category_id: category_id ?? this.category_id,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      price: price ?? this.price,
      packingcharges: packingcharges ?? this.packingcharges,
      discountPrice: discountPrice ?? this.discountPrice,
      item: item ?? this.item,
      groceryWeight: groceryWeight ?? this.groceryWeight,
      groceryUnit: groceryUnit ?? this.groceryUnit,
      vendorID: vendorID ?? this.vendorID,
      quantity: quantity ?? this.quantity,
      extras_price: extras_price ?? this.extras_price,
      extras: extras ?? this.extras,
      variant_info: variant_info ?? this.variant_info,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category_id.present) {
      map['category_id'] = Variable<String>(category_id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (photo.present) {
      map['photo'] = Variable<String>(photo.value);
    }
    if (price.present) {
      map['price'] = Variable<String>(price.value);
    }
    if (packingcharges.present) {
      map['packingcharges'] = Variable<String>(packingcharges.value);
    }
    if (discountPrice.present) {
      map['discount_price'] = Variable<String?>(discountPrice.value);
    }
    if (item.present) {
      map['item'] = Variable<String?>(item.value);
    }
    if (groceryWeight.present) {
      map['groceryWeight'] = Variable<String?>(groceryWeight.value);
    }
    if (groceryUnit.present) {
      map['groceryUnit'] = Variable<String?>(groceryUnit.value);
    }
    if (vendorID.present) {
      map['vendor_i_d'] = Variable<String>(vendorID.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (extras_price.present) {
      map['extras_price'] = Variable<String?>(extras_price.value);
    }
    if (extras.present) {
      map['extras'] = Variable<String?>(extras.value);
    }
    if (variant_info.present) {
      map['variant_info'] = Variable<String?>(variant_info.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CartProductsCompanion(')
          ..write('id: $id, ')
          ..write('category_id: $category_id, ')
          ..write('name: $name, ')
          ..write('photo: $photo, ')
          ..write('price: $price, ')
          ..write('packingcharges: $packingcharges, ')
          ..write('discountPrice: $discountPrice, ')
          ..write('item: $item, ')
          ..write('groceryUnit: $groceryUnit, ')
          ..write('groceryWeight: $groceryWeight, ')
          ..write('vendorID: $vendorID, ')
          ..write('quantity: $quantity, ')
          ..write('extras_price: $extras_price, ')
          ..write('extras: $extras, ')
          ..write('variant_info: $variant_info, ')
          ..write(')'))
        .toString();
  }
}

class $CartProductsTable extends CartProducts
    with TableInfo<$CartProductsTable, CartProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;

  $CartProductsTable(this.attachedDatabase, [this._alias]);

  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String?> id = GeneratedColumn<String?>(
    'id',
    aliasedName,
    false,
    type: const StringType(),
    requiredDuringInsert: true,
  );

  final VerificationMeta _categoryIdMeta = const VerificationMeta(
    'category_id',
  );
  late final GeneratedColumn<String?> categoryId = GeneratedColumn<String?>(
    'category_id',
    aliasedName,
    false,
    type: const StringType(),
    requiredDuringInsert: true,
  );

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: const StringType(),
    requiredDuringInsert: true,
  );

  final VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<String?> photo = GeneratedColumn<String?>(
    'photo',
    aliasedName,
    false,
    type: const StringType(),
    requiredDuringInsert: true,
  );

  final VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<String?> packingcharges = GeneratedColumn<String?>(
    'packingcharges',
    aliasedName,
    false,
    type: const StringType(),
    requiredDuringInsert: true,
  );
  final VerificationMeta _packingcharges = const VerificationMeta(
    'packingcharges',
  );
  @override
  late final GeneratedColumn<String?> price = GeneratedColumn<String?>(
    'price',
    aliasedName,
    false,
    type: const StringType(),
    requiredDuringInsert: true,
  );
  final VerificationMeta _discountPriceMeta = const VerificationMeta(
    'discountPrice',
  );
  @override
  late final GeneratedColumn<String?> discountPrice = GeneratedColumn<String?>(
    'discount_price',
    aliasedName,
    true,
    type: const StringType(),
    requiredDuringInsert: false,
  );

  final VerificationMeta _itemMeta = const VerificationMeta('item');
  late final GeneratedColumn<String?> item = GeneratedColumn<String?>(
    'item',
    aliasedName,
    true,
    type: const StringType(),
    requiredDuringInsert: false,
  );
  final VerificationMeta _groceryUnitMeta = const VerificationMeta(
    'groceryUnit',
  );
  late final GeneratedColumn<String?> groceryUnit = GeneratedColumn<String?>(
    'groceryUnit',
    aliasedName,
    true,
    type: const StringType(),
    requiredDuringInsert: false,
  );
  final VerificationMeta _groceryWeightMeta = const VerificationMeta(
    'groceryWeight',
  );
  late final GeneratedColumn<String?> groceryWeight = GeneratedColumn<String?>(
    'groceryWeight',
    aliasedName,
    true,
    type: const StringType(),
    requiredDuringInsert: false,
  );

  final VerificationMeta _vendorIDMeta = const VerificationMeta('vendorID');
  @override
  late final GeneratedColumn<String?> vendorID = GeneratedColumn<String?>(
    'vendor_i_d',
    aliasedName,
    false,
    type: const StringType(),
    requiredDuringInsert: true,
  );

  final VerificationMeta _quantityMeta = const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int?> quantity = GeneratedColumn<int?>(
    'quantity',
    aliasedName,
    false,
    type: const IntType(),
    requiredDuringInsert: true,
  );

  final VerificationMeta _extras_priceMeta = const VerificationMeta(
    'extras_price',
  );
  @override
  late final GeneratedColumn<String?> extras_price = GeneratedColumn<String?>(
    'extras_price',
    aliasedName,
    true,
    type: const StringType(),
    requiredDuringInsert: false,
  );

  final VerificationMeta _extrasMeta = const VerificationMeta('extras');
  @override
  late final GeneratedColumn<String?> extras = GeneratedColumn<String?>(
    'extras',
    aliasedName,
    true,
    type: const StringType(),
    requiredDuringInsert: false,
  );

  final VerificationMeta _veriant_infoMeta = const VerificationMeta(
    'variant_info',
  );
  late final GeneratedColumn<String?> variant_info = GeneratedColumn<String?>(
    'variant_info',
    aliasedName,
    true,
    type: const StringType(),
    requiredDuringInsert: false,
  );

  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    name,
    photo,
    price,
    packingcharges,
    discountPrice,
    item,
    groceryWeight,
    groceryUnit,
    vendorID,
    quantity,
    extras_price,
    extras,
    variant_info,
  ];

  @override
  String get aliasedName => _alias ?? 'cart_products';

  @override
  String get actualTableName => 'cart_products';

  @override
  VerificationContext validateIntegrity(
    Insertable<CartProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('photo')) {
      context.handle(
        _photoMeta,
        photo.isAcceptableOrUnknown(data['photo']!, _photoMeta),
      );
    } else if (isInserting) {
      context.missing(_photoMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }

    if (data.containsKey('discount_price')) {
      context.handle(
        _discountPriceMeta,
        discountPrice.isAcceptableOrUnknown(
          data['discount_price']!,
          _discountPriceMeta,
        ),
      );
    }
    if (data.containsKey('item')) {
      context.handle(
        _itemMeta,
        item.isAcceptableOrUnknown(data['item']!, _itemMeta),
      );
    }
    if (data.containsKey('groceryWeight')) {
      context.handle(
        _groceryWeightMeta,
        groceryWeight.isAcceptableOrUnknown(
          data['groceryWeight']!,
          _groceryWeightMeta,
        ),
      );
    }
    if (data.containsKey('groceryUnit')) {
      context.handle(
        _groceryUnitMeta,
        groceryUnit.isAcceptableOrUnknown(
          data['groceryUnit']!,
          _groceryUnitMeta,
        ),
      );
    }
    if (data.containsKey('packingcharges')) {
      context.handle(
        _packingcharges,
        packingcharges.isAcceptableOrUnknown(
          data['packingcharges']!,
          _packingcharges,
        ),
      );
    }
    if (data.containsKey('vendor_i_d')) {
      context.handle(
        _vendorIDMeta,
        vendorID.isAcceptableOrUnknown(data['vendor_i_d']!, _vendorIDMeta),
      );
    } else if (isInserting) {
      context.missing(_vendorIDMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('extras_price')) {
      context.handle(
        _extras_priceMeta,
        extras_price.isAcceptableOrUnknown(
          data['extras_price']!,
          _extras_priceMeta,
        ),
      );
    }
    if (data.containsKey('extras')) {
      context.handle(
        _extrasMeta,
        extras.isAcceptableOrUnknown(data['extras']!, _extrasMeta),
      );
    }
    if (data.containsKey('variant_info')) {
      context.handle(
        _veriant_infoMeta,
        variant_info.isAcceptableOrUnknown(
          data['variant_info']!,
          _veriant_infoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};

  @override
  CartProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    return CartProduct.fromData(
      data,
      attachedDatabase,
      prefix: tablePrefix != null ? '$tablePrefix.' : null,
    );
  }

  @override
  $CartProductsTable createAlias(String alias) {
    return $CartProductsTable(attachedDatabase, alias);
  }
}

abstract class _$CartDatabase extends GeneratedDatabase {
  _$CartDatabase(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  late final $CartProductsTable cartProducts = $CartProductsTable(this);

  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cartProducts];
}
