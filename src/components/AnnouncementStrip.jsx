import {useState} from 'react';
import {Pause,Play} from 'lucide-react';
import './AnnouncementStrip.css';
const messages=['Delivery across Pakistan · Rs. 300','Your design, your rules','Custom hoodies & everyday essentials'];
export default function AnnouncementStrip(){
 const [paused,setPaused]=useState(false);
 return <div className={`announcement hood-announcement${paused?' is-paused':''}`}><span className="visually-hidden">{messages.join('. ')}</span><div className="hood-announcement__viewport" aria-hidden="true"><div className="hood-announcement__track">{[0,1].map(group=><div className="hood-announcement__group" key={group}>{[0,1,2].flatMap(repeat=>messages.map((message,index)=><span key={`${repeat}-${index}`}>{message}<i>✦</i></span>))}</div>)}</div></div><button className="hood-announcement__pause" type="button" onClick={()=>setPaused(!paused)} aria-label={paused?'Play announcement':'Pause announcement'} aria-pressed={paused}>{paused?<Play size={12}/>:<Pause size={12}/>}</button></div>;
}
