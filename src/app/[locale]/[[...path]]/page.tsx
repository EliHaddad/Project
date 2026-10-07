import Workspace from '@/components/Workspace';
export default async function Page({params}:{params:Promise<{locale:string;path?:string[]}>}) {const {path=[]}=await params;return <Workspace path={path}/>;}
