import 'package:flutter_test/flutter_test.dart';
import 'package:xroneadminpanel/features/store/models/store_model.dart';

void main() {
  group('Store order delivery address', () {
    test(
      'reads the order shipping address foreign key used by Pilot Store',
      () {
        final order = StoreOrder.fromMap({
          'id': 'order-1',
          'shipping_address_id': 'address-1',
        });

        expect(order.addressId, 'address-1');
        expect(order.deliveryAddress, isEmpty);
      },
    );

    test('resolves only the address referenced by the order', () {
      final order = StoreOrder.fromMap({
        'id': 'order-1',
        'owner_id': 'customer-1',
        'shipping_address_id': 'address-2',
      });
      final expectedAddress = StoreAddress.fromMap({
        'id': 'address-2',
        'owner_id': 'customer-1',
        'address_line1':
            'House 42, Lake View, Church Street, Bengaluru, '
            'Karnataka, 560001, India',
        'postal_code': '560001',
      });
      final data = StoreAdminData(
        categories: const [],
        products: const [],
        images: const [],
        orders: [order],
        orderItems: const [],
        addresses: [
          StoreAddress.fromMap({
            'id': 'address-1',
            'owner_id': 'customer-1',
            'address_line1': 'A different saved address',
          }),
          expectedAddress,
        ],
        carts: const [],
        cartItems: const [],
        wishlistItems: const [],
      );

      expect(data.addressForOrder(order), same(expectedAddress));
    });

    test('preserves the original canonical Pilot Store address verbatim', () {
      const canonical =
          'Flat 7B, Pilot Heights, MG Road, Opposite Metro Gate 2, '
          'Indiranagar, Bengaluru, Karnataka, 560038, India';
      final address = StoreAddress.fromMap({
        'id': 'address-1',
        'address_line1': canonical,
        'address_line2': 'must not be appended',
        'city': 'Wrong city',
        'state': 'Wrong state',
        'postal_code': '560038',
        'country': 'Wrong country',
      });

      expect(address.address, canonical);
    });

    test('matches Pilot Store formatting for older split addresses', () {
      final address = StoreAddress.fromMap({
        'id': 'address-2',
        'address_line1': 'Flat 7B',
        'address_line2': 'Pilot Heights, MG Road, Opposite Metro Gate 2',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'postal_code': '560038',
        'country': 'India',
      });

      expect(
        address.address,
        'Flat 7B, Pilot Heights, MG Road, Opposite Metro Gate 2, '
        'Bengaluru, Karnataka, 560038, India',
      );
    });
  });
}
