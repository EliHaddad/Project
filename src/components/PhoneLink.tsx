export default function PhoneLink({value}:{value:string|number|boolean|null|undefined}){
 const display=String(value??'').trim();
 if(!display)return <>—</>;
 const number=display.replace(/[^\d+]/g,'');
 if(!/^\+?\d{3,15}$/.test(number))return <bdi>{display}</bdi>;
 return <a className="phone-link" href={`tel:${number}`}><bdi>{display}</bdi></a>;
}
