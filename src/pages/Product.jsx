import BundlePurchasePanel from '../components/product/BundlePurchasePanel';
import {addBundleToCart} from '../services/bundles';
import InquiryPurchasePanel from '../components/product/InquiryPurchasePanel';
import { useState } from "react";
import { useParams, Link, useNavigate, useSearchParams } from "react-router-dom";
import { toast } from "sonner";
import { getProduct } from "../services/catalog";
import { addToCart } from "../services/cart";
import { addToWishlist } from "../services/wishlist";
import { useQuery } from "../hooks/useQuery";
import { useAuth } from "../hooks/useAuth";
import { usePageMetadata } from "../hooks/usePageMetadata";
import { Loading, ErrorState, Empty } from "../components/Feedback";
import ProductGallery from "../components/ProductGallery";
import Reviews from "../components/Reviews";
import ProductInfo from "../components/product/ProductInfo";
import VariantSelector from "../components/product/VariantSelector";
import PurchasePanel from "../components/product/PurchasePanel";
import ProductAccordion from "../components/product/ProductAccordion";
import RecommendationCarousel from "../components/product/RecommendationCarousel";
import { imageUrl } from "../lib/supabase";
import { productOptions, galleryImages } from "../lib/productOptions";
import "../styles/product-detail.css";

export default function Product() {
  const { id } = useParams();
  const [params]=useSearchParams();
  return <ProductDetail key={`${id}:${params.get('colour')||''}`} id={id} />;
}

function ProductDetail({ id }) {
  const { user } = useAuth();
  const navigate=useNavigate();
  const [searchParams]=useSearchParams();
  const query = useQuery(() => getProduct(id), [id]);
  const [color, setColor] = useState(()=>searchParams.get('colour')||null);
  const [size, setSize] = useState(null);
  const [busy, setBusy] = useState(false);
  const [customisationNote,setCustomisationNote]=useState('');
  const product = query.data;
  const options = productOptions(product?.product_variants, color);
  const selectedVariant = options.variants.find((variant) => variant.size === size);
  const needsAvailability=product?.enquiry_only||!(product?.product_variants||[]).some(variant=>variant.active);
  const activeColour=needsAvailability?((product?.inquiry_colours||[]).some(option=>option.color===color)?color:product?.inquiry_colours?.[0]?.color||''):options.colour;

  const displayOptions=options.colours.length?options:{...options,colours:(product?.inquiry_colours||[]).map(option=>option.color),colour:activeColour};

  usePageMetadata({
    title: product?.name || "Product",
    description: product?.description?.slice(0, 160) || "Discover a considered piece from the HOOD.",
    image: imageUrl(product?.product_images?.[0]?.path),
    type: "product",
    noindex: !product || product.status !== "published",
  });

  if (query.loading && !query.data) return <Loading label="Opening this piece…" />;
  if (query.error) return <ErrorState error={query.error} retry={query.refresh} />;
  if (!product || product.status !== "published")
    return (
      <Empty
        title="This piece is no longer available"
        text="Browse the rest of the collection instead."
        link="/shop"
        action="View the collection"
      />
    );

  async function handleAddToCart(quantity,buyNow=false) {
    if(product.enquiry_only)return toast.error("Please enquire on WhatsApp to confirm pricing and availability.");
    if (!user) return toast.error("Please sign in to add items to your bag.");
    if (!selectedVariant) return toast.error("Please choose a colour and size.");
    setBusy(true);
    try {
      await addToCart(selectedVariant.id, quantity, customisationNote);
      toast.success("Added to your bag.");
      if(buyNow)navigate("/checkout");
    } catch (error) {
      toast.error(error.message);
    } finally {
      setBusy(false);
    }
  }

  async function handleBundle(selections,quantity,buyNow=false){
    if(!user)return toast.error('Please sign in to order this bundle.');
    setBusy(true);try{await addBundleToCart(product.id,selections,quantity,customisationNote);toast.success('Bundle added to your bag');if(buyNow)navigate('/checkout');}catch(error){toast.error(error.message);}finally{setBusy(false);}
  }
  async function handleWishlist() {
    if (!user) return toast.error("Please sign in to save pieces.");
    try {
      await addToWishlist(user.id, product.id);
      toast.success("Saved to your wishlist.");
    } catch (error) {
      toast.error(error.message);
    }
  }

  return (
    <div className="page product-detail product-detail--editorial">
      <div className="product-detail-grid">
        <ProductGallery key={activeColour} images={galleryImages(product.product_images, activeColour)} />
        <ProductInfo product={product} selectedVariant={selectedVariant}>
          <div className="hood-product-note"><label htmlFor="customisation-note">Customisation note <span>(optional)</span></label><textarea id="customisation-note" value={customisationNote} onChange={event=>setCustomisationNote(event.target.value)} maxLength={2000} rows={3} placeholder="For example: print the text in blue instead of white." aria-describedby="customisation-note-help"/><div id="customisation-note-help"><span>Your note will be attached to this item for our team.</span><span>{customisationNote.length}/2000</span></div></div>
          {product.is_bundle?<BundlePurchasePanel product={product} onAdd={(s,q)=>handleBundle(s,q)} onBuy={(s,q)=>handleBundle(s,q,true)} busy={busy}/>:product.enquiry_only?<InquiryPurchasePanel product={product} colour={activeColour} onColourChange={setColor}/>:<>
          <VariantSelector options={displayOptions} allVariants={product.product_variants||[]} colourSwatches={product.inquiry_colours||[]} size={size} onColorChange={value=>{setColor(value);setSize(null);}} onSizeChange={setSize}/>
          <PurchasePanel selectedVariant={selectedVariant} onAddToCart={handleAddToCart} onWishlist={handleWishlist} onBuyNow={quantity=>handleAddToCart(quantity,true)} product={product} colour={options.colour} size={size} busy={busy}/>
          {!selectedVariant&&<p className="product-selection-note">{options.variants.length?'Choose a size to add this piece to your bag.':'Sizes and stock are being updated. Online ordering will open here shortly.'}</p>}
          {!user&&<p className="product-signin-note"><Link to={'/login?returnTo='+encodeURIComponent('/product/'+id)}>Sign in</Link> to shop and save your favourites.</p>}
          </>}
          <Link className="hood-size-link" to="/size-guide">Size guide ↗</Link>
          <ProductAccordion product={product}/>
          <Link className="product-back-link" to="/shop">Back to the collection</Link>
        </ProductInfo>
      </div>
      {!product.enquiry_only&&<Reviews productId={product.id}/>}
      <RecommendationCarousel productId={product.id} categoryId={product.category_id}/>
    </div>
  );
}
