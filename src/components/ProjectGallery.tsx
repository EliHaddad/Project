'use client';
import {useTranslations} from 'next-intl';
import type {Row} from '@/lib/model';

const ashdodImages=['Cam008_reg.jpg','Cam004_reg.jpg','rova-ashdod-shtila-0026-low-env_0.jpg','Cam009_reg.jpg','Cam006_reg.jpg','Cam003_reg.jpg','Cam001_reg-1.jpg','Cam001_night.jpg','177.jpg','089.jpg','033.jpg','027.jpg','009.jpg','001.jpg','002.jpg','003.jpg'];
const source='https://elihaddad-agents.com/גני-בראשית-רובע-מיוחד-אשדוד/';
export default function ProjectGallery({project}:{project:Row}){
 const t=useTranslations();
 if(project.id!=='2'||project.city!=='Ashdod')return null;
 return <section className="panel project-gallery"><div className="gallery-heading"><h2>{t('projectImages')}</h2><span className="muted">{ashdodImages.length} {t('images')}</span></div><p className="muted">{t('projectImagesHelp')}</p><div className="project-gallery-grid">{ashdodImages.map((name,index)=>{const url=`https://elihaddad-agents.com/wp-content/uploads/2026/04/${name}`;return <a key={name} href={url} target="_blank" rel="noopener noreferrer" aria-label={t('openProjectImage',{number:index+1})}><img src={url} alt={t('ashdodImage',{number:index+1})} loading={index<2?'eager':'lazy'} width={720} height={480}/></a>;})}</div><a className="gallery-source" href={source} target="_blank" rel="noopener noreferrer">{t('imageSource')} : Eli Haddad · Ganei Bereshit</a></section>;
}
