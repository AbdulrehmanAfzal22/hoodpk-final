export const DELIVERY_CENTS=30000;
export const ADVANCE_THRESHOLD_CENTS=1000000;
// Threshold uses the payable order total, including delivery. Values are paisa.
export function checkoutPolicy(subtotal){const total=Number(subtotal)+DELIVERY_CENTS;const advanceRequired=total>ADVANCE_THRESHOLD_CENTS;const payableNow=advanceRequired?Math.ceil(total/2):total;return {total,advanceRequired,payableNow,balanceOnDelivery:total-payableNow};}
