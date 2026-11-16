import {imageUrl} from '../lib/supabase';
import {bundleCardTiles} from '../lib/bundleCardTiles.mjs';
import './BundleCardCollage.css';
export default function BundleCardCollage({product}){
 const tiles=bundleCardTiles(product),columns=tiles.length<=4?2:3,rows=Math.ceil(tiles.length/columns);
 return <div className={`bundle-card-collage bundle-card-collage--${tiles.length}`} style={{'--bundle-columns':columns,'--bundle-rows':rows,'--bundle-min-height':`${Math.max(300,rows*90)}px`}} aria-label={`${product.name}: ${tiles.length} included products`}><span className="bundle-card-collage__count">{tiles.length} PIECE BUNDLE</span>{tiles.map(tile=><div className="bundle-card-collage__tile" key={tile.id}>{tile.path?<img src={imageUrl(tile.path)} alt={tile.name} loading="lazy" decoding="async"/>:<span className="bundle-card-collage__missing">{tile.name}</span>}<span className="bundle-card-collage__name">{tile.name}</span></div>)}</div>;
}
