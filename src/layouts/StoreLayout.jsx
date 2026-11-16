import StoreMotion from '../components/StoreMotion';
import AnnouncementStrip from '../components/AnnouncementStrip';
import {Outlet,useLocation} from 'react-router-dom';
import {motion,useReducedMotion} from 'framer-motion';
import {getStoreRouteMetadata} from '../config/routeMetadata';
import {usePageMetadata} from '../hooks/usePageMetadata';
import LuxuryHeader from '../components/LuxuryHeader';
import LuxuryFooter from '../components/LuxuryFooter';
import './StoreLayout.css';
export default function StoreLayout(){
	const location=useLocation();
	const reducedMotion=useReducedMotion();
	const home=location.pathname==='/';
	const metadata=getStoreRouteMetadata(location.pathname,location.search);
	usePageMetadata(metadata);

	return <>
		<a className="skip-link" href="#main">Skip to content</a>
		<StoreMotion/><AnnouncementStrip/>
		<LuxuryHeader home={home}/>
		<motion.main id="main" tabIndex="-1" initial={{opacity:1}} animate={{opacity:1}} exit={{opacity:0}} transition={{duration:reducedMotion?0:.45,ease:[.22,1,.36,1]}}><Outlet/></motion.main>
		<LuxuryFooter/>
	</>;
}
