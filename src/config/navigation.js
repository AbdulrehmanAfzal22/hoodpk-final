import {BarChart3,Boxes,Instagram,LayoutDashboard,MessageSquare,Package,ShoppingBag,Star,Tags,Users} from 'lucide-react';

export const storeNavigation=[{label:'Shop',to:'/shop'},{label:'Categories',to:'/#categories'},{label:'Customise',to:'/customise'},{label:'Combo Deals',to:'/shop?category=combo-deals-bundles'},{label:'About Us',to:'/about'}];

export const customerNavigation=[
  {label:'My account',to:'/account'},
  {label:'Order history',to:'/orders'},
  {label:'Saved pieces',to:'/wishlist'},
  {label:'Shopping bag',to:'/cart'},
];

export const exploreNavigation=[
  {label:'The collection',to:'/shop'},
  {label:'Collections',to:'/collections'},
  {label:'Accessories',to:'/accessories'},
  {label:'Our perspective',to:'/about'},
  {label:'Contact support',to:'/contact-support'},
];

export const adminNavigation=[
  {label:'Overview',to:'/admin',Icon:LayoutDashboard,end:true},
  {label:'Combos & Bundles',to:'/admin/bundles',Icon:Boxes},
  {label:'All Products',to:'/admin/products',Icon:Package},
  {label:'Collections',to:'/admin/collections',Icon:Tags},
  {label:'Instagram Reels',to:'/admin/instagram-reels',Icon:Instagram},
  {label:'Inventory',to:'/admin/inventory',Icon:Boxes},
  {label:'Orders',to:'/admin/orders',Icon:ShoppingBag},
  {label:'Payments',to:'/admin/payments',Icon:ShoppingBag},
  {label:'Newsletter',to:'/admin/newsletter',Icon:MessageSquare},
  {label:'Customers',to:'/admin/customers',Icon:Users},
  {label:'Analytics',to:'/admin/analytics',Icon:BarChart3},
  {label:'Reviews',to:'/admin/reviews',Icon:Star},
];