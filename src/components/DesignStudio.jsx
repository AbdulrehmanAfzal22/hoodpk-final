import {ArrowUpRight} from 'lucide-react';
import {whatsappLink} from '../config/hoodStore';
import '../styles/simple-store-panels.css';
export default function DesignStudio(){
 return <section className="hood-simple-panel hood-simple-panel--custom" id="customise-your-hood" aria-labelledby="customise-hood-title"><div><h2 id="customise-hood-title">Customise your HOOD</h2><p>Add your own picture, text or design to a hoodie. Share your idea with us on WhatsApp and we’ll help you customise it.</p></div><a className="hood-simple-panel__button" href={whatsappLink('Hi THE HOOD.PK! I would like to customise a hoodie. I will share my picture, text or design.')} target="_blank" rel="noreferrer">Customise on WhatsApp <ArrowUpRight size={17} aria-hidden="true"/></a></section>;
}
