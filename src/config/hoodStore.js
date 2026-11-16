export const STORE_NAME='THE HOOD.PK';
export const WHATSAPP_NUMBER=(import.meta.env.VITE_WHATSAPP_NUMBER||'923098670057').replace(/\D/g,'');
export const INSTAGRAM_URL=import.meta.env.VITE_INSTAGRAM_URL||'';
export const CATEGORIES=[
 {slug:'customised-hoodies',name:'Customised Hoodies',tag:'Your design. Your rules.',customise:true},
 {slug:'printed',name:'Printed',tag:'Wear your personality.'},
 {slug:'plain-hoodies',name:'Plain Hoodies',tag:'Everyday essentials.'},
 {slug:'zipper-hoodies',name:'Zipper Hoodies',tag:'Layer it your way.'},
 {slug:'sweatshirts',name:'Sweatshirts',tag:'An easy favourite.'},
 {slug:'t-shirts',name:'T-Shirts',tag:'Make it yours.',customise:true},
 {slug:'combo-deals-bundles',name:'Combo Deals / Bundles',tag:'Better together.'},
];
export function whatsappLink(message='Hi THE HOOD.PK! I would like to enquire about your products.') {return `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(message)}`;}
export function customisationMessage({name='',colour='',size='',quantity=1,url=''}={}){return ["Hi THE HOOD.PK! I'd like to customise my own hoodie or T-shirt.",name&&`Product: ${name}`,colour&&`Colour: ${colour}`,size&&`Size: ${size}`,`Quantity: ${quantity}`,url&&`Product link: ${url}`,'I would like to share my reference pictures, text or design. Please guide me with pricing and availability.'].filter(Boolean).join('\n');}
export const ABOUT_TEXT='At THE HOOD.PK, we believe your clothing should reflect your personality. We specialise in customisable hoodies, T-shirts and everyday essentials that let you express yourself through your own designs. From personalised prints to ready-to-wear pieces, we’re here to make your ideas wearable.';
export const CUSTOMISE_TEXT='Your design, your rules! At THE HOOD.PK, you can customise your own hoodie or T-shirt with your favourite pictures, text, quotes or designs. Contact us via WhatsApp and share your reference.';
export const FAQS=[
 ['How can I place an order?','You can browse our website, select your favourite product, choose your size and add it to your cart. You can also place an order directly through WhatsApp.'],
 ['Can I customise my own hoodie?','Absolutely! We offer personalised designs. Contact us through WhatsApp with your reference pictures, text or ideas.'],
 ['What sizes are available?','We offer multiple sizes. Please refer to our Size Guide before placing your order.'],
 ['Do you offer Cash on Delivery?','Yes, Cash on Delivery is available across Pakistan. Orders above Rs. 10,000/- require a 50% advance payment through Bank Transfer or EasyPaisa.'],
 ['How long does delivery take?','Orders are generally delivered within 3–7 working days.'],
 ['Can I exchange my order?','Exchanges are subject to our exchange policy. Please contact us if you receive a damaged or incorrect product. Customised pieces cannot be exchanged or returned.'],
 ['Can I order in bulk?','Yes! For bulk orders, customised sets or special requirements, contact us directly through WhatsApp for discounted pricing.'],
];
