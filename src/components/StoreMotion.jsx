import {useEffect} from 'react';
import {useLocation} from 'react-router-dom';
import '../styles/studio-motion.css';
export default function StoreMotion(){
 const location=useLocation();
 useEffect(()=>{
  if(!window.IntersectionObserver||window.matchMedia('(prefers-reduced-motion: reduce)').matches)return;
  const root=document.getElementById('main');if(!root)return;
  const observer=new IntersectionObserver(entries=>{for(const entry of entries)if(entry.isIntersecting){entry.target.classList.add('hood-in-view');observer.unobserve(entry.target);}},{threshold:.07,rootMargin:'0px 0px -24px 0px'});
  const selector='.hood-section__heading,.hood-category,.hood-home-products__grid>.luxury-product-card,.shop-product-grid__item,.hood-why>div,.hood-simple-panel,.hood-newsletter__card,.hood-review-card,.product-info>h1';
  let frame;
  function scan(){cancelAnimationFrame(frame);frame=requestAnimationFrame(()=>{root.querySelectorAll(selector).forEach((node,i)=>{if(node.dataset.hoodMotion)return;node.dataset.hoodMotion='true';node.style.setProperty('--reveal-delay',`${i%4*55}ms`);node.classList.add('hood-reveal');observer.observe(node);});});}
  const mutations=new MutationObserver(scan);mutations.observe(root,{childList:true,subtree:true});scan();
  return()=>{cancelAnimationFrame(frame);mutations.disconnect();observer.disconnect();root.querySelectorAll('.hood-reveal').forEach(node=>{node.classList.remove('hood-reveal','hood-in-view');delete node.dataset.hoodMotion;});};
 },[location.pathname]);
 return null;
}
