using System;
using System.Collections;
using RoR2.ContentManagement;
using UnityEngine;
using Path = System.IO.Path;

namespace WaffleHouse.Content
{
    public class ContentProvider : IContentPackProvider
    {
        public string identifier => WaffleHouseStage.GUID + "." + nameof(ContentProvider);

		private readonly ContentPack _contentPack = new ContentPack();

        public static String assetDirectory;

		public IEnumerator LoadStaticContentAsync(LoadStaticContentAsyncArgs args)
        {
            _contentPack.identifier = identifier;

            var assetsFolderFullPath = Path.Combine(Path.GetDirectoryName(typeof(ContentProvider).Assembly.Location), "assetbundles");
            assetDirectory = assetsFolderFullPath;


            AssetBundle scenesAssetBundle = null;
            yield return LoadAssetBundle(
                Path.Combine(assetsFolderFullPath, WaffleHouseContent.ScenesAssetBundleFileName),
                args.progressReceiver,
                (assetBundle) => scenesAssetBundle = assetBundle);

            AssetBundle assetsAssetBundle = null;
            yield return LoadAssetBundle(
                Path.Combine(assetsFolderFullPath, WaffleHouseContent.AssetsAssetBundleFileName),
                args.progressReceiver,
                (assetBundle) => assetsAssetBundle = assetBundle);

            yield return WaffleHouseContent.LoadAssetBundlesAsync(
                scenesAssetBundle, assetsAssetBundle,
                args.progressReceiver,
                _contentPack);

            yield break;
        }

        private IEnumerator LoadAssetBundle(string assetBundleFullPath, IProgress<float> progress, Action<AssetBundle> onAssetBundleLoaded)
        {
			var assetBundleCreateRequest = AssetBundle.LoadFromFileAsync(assetBundleFullPath);
			while (!assetBundleCreateRequest.isDone)
			{
				progress.Report(assetBundleCreateRequest.progress);
				yield return null;
			}

			onAssetBundleLoaded(assetBundleCreateRequest.assetBundle);

			yield break;
		}

        public IEnumerator GenerateContentPackAsync(GetContentPackAsyncArgs args)
        {
			ContentPack.Copy(_contentPack, args.output);

			args.ReportProgress(1f);
			yield break;
		}

        public IEnumerator FinalizeAsync(FinalizeAsyncArgs args)
        {
            args.ReportProgress(1f);
            yield break;
        }
    }
}
