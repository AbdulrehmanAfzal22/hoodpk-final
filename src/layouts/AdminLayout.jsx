import {useEffect,useState} from 'react';
import {Outlet,useLocation} from 'react-router-dom';
import {useAuth} from '../hooks/useAuth';
import {usePageMetadata} from '../hooks/usePageMetadata';
import {supabase} from '../lib/supabase';
import AdminSidebar from '../components/admin/AdminSidebar';
import AdminHeader from '../components/admin/AdminHeader';
import './AdminLayout.css';
import '../components/admin/admin-experience.css';
import './AdminMobile.css';

const adminTitles={'/admin':'Dashboard','/admin/bundles':'Combos & Bundles','/admin/products':'All Products','/admin/products/create':'Create product','/admin/categories':'Collections','/admin/collections':'Collections','/admin/accessories':'Accessories','/admin/orders':'Orders','/admin/customers':'Customers','/admin/inventory':'Inventory','/admin/analytics':'Analytics','/admin/reviews':'Reviews Management','/admin/support':'Support Inbox'};

export default function AdminLayout(){
  const {user}=useAuth();
  const location=useLocation();
  const title=location.pathname.includes('/edit')?'Edit product':adminTitles[location.pathname]||'Administration';
  const [collapsed,setCollapsed]=useState(()=>window.innerWidth<=1100);
  const [mobileOpen,setMobileOpen]=useState(false);
  const [isMobile,setIsMobile]=useState(()=>window.matchMedia('(max-width:900px)').matches);
  useEffect(()=>{const media=window.matchMedia('(max-width:900px)');const update=()=>{setIsMobile(media.matches);if(!media.matches)setMobileOpen(false);};media.addEventListener('change',update);return()=>media.removeEventListener('change',update);},[]);
  useEffect(()=>setMobileOpen(false),[location.pathname,location.search]);
  useEffect(()=>{if(!mobileOpen)return;const overflow=document.body.style.overflow;const previous=document.querySelector('.admin-header__menu');document.body.style.overflow='hidden';return()=>{document.body.style.overflow=overflow;previous?.focus?.();};},[mobileOpen]);
  const desktopCollapsed=collapsed&&!isMobile;
  useEffect(()=>{if(!mobileOpen)return;const closeOnEscape=event=>{if(event.key==='Escape')setMobileOpen(false);};window.addEventListener('keydown',closeOnEscape);return()=>window.removeEventListener('keydown',closeOnEscape);},[mobileOpen]);
  usePageMetadata({title:`${title} · Studio`,description:'the HOOD store administration.',noindex:true});

  return <div className={`admin-layout admin-layout--premium ${desktopCollapsed?'is-collapsed':''}`}>
    <AdminSidebar user={user} isMobile={isMobile} collapsed={desktopCollapsed} mobileOpen={mobileOpen} onToggle={()=>setCollapsed(value=>!value)} onClose={()=>setMobileOpen(false)} onSignOut={()=>supabase.auth.signOut()}/>
    <div className="admin-main" inert={isMobile&&mobileOpen?true:undefined}><AdminHeader pathname={location.pathname} user={user} isMobile={isMobile} collapsed={desktopCollapsed} mobileOpen={mobileOpen} onToggle={()=>setCollapsed(value=>!value)} onMenu={()=>setMobileOpen(true)}/><main className="admin-content"><Outlet/></main></div>
  </div>;
}
