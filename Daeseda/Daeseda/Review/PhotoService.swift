import Photos
import UIKit

enum MediaType {
  case all
  case image
  case video
}

final class PhotoService: NSObject {
  static let shared = PhotoService()
  weak var delegate: PHPhotoLibraryChangeObserver?
  
  override private init() {
    super.init()
    // PHPhotoLibraryChangeObserver 델리게이트
    // PHPhotoLibrary: 변경사항을 알려 데이터 리프레시에 사용
    PHPhotoLibrary.shared().register(self)
  }
  
  private enum Const {
    static let titleText: (MediaType?) -> String = { mediaType in
      switch mediaType {
      case .all:
        return "이미지와 동영상"
      case .image:
        return "이미지"
      case .video:
        return "동영상"
      default:
        return "비어있는 타이틀"
      }
    }
    static let predicate: (MediaType) -> NSPredicate = { mediaType in
      let format = "mediaType == %d"
      switch mediaType {
      case .all:
        return .init(
          format: format + " || " + format,
          PHAssetMediaType.image.rawValue,
          PHAssetMediaType.video.rawValue
        )
      case .image:
        return .init(
          format: format,
          PHAssetMediaType.image.rawValue
        )
      case .video:
        return .init(
          format: format,
          PHAssetMediaType.video.rawValue
        )
      }
    }
    static let sortDescriptors = [
      NSSortDescriptor(key: "creationDate", ascending: false),
      NSSortDescriptor(key: "modificationDate", ascending: false)
    ]
  }
  
  let imageManager = PHCachingImageManager()
  
  deinit {
    PHPhotoLibrary.shared().unregisterChangeObserver(self)
  }
  
  func getAlbums(mediaType: MediaType, completion: @escaping ([AlbumInfo]) -> Void) {
    var allAlbums = [AlbumInfo]()
    defer {
      completion(allAlbums)
    }
    
      //일반 앨범 정보 가져오기
    // PHFetchOptions: predicate를 이용하여 sorting, mediaType 등을 쿼리하는데 사용
    let fetchOptions = PHFetchOptions()
    fetchOptions.predicate = Const.predicate(mediaType)
    let standardAlbum = PHAsset.fetchAssets(with: fetchOptions)
      //PHAsset.fetchAssets(with:) 메소드 : 앨범 가져올때
    allAlbums.append(
      .init(
        id: nil,
        name: Const.titleText(mediaType),
        count: standardAlbum.count,
        album: standardAlbum
      )
    )
    
      // 스마트 앨범 조회
    let smartAlbums = PHAssetCollection.fetchAssetCollections(
      with: .smartAlbum,
      subtype: .any,
      options: PHFetchOptions()
    )
    guard 0 < smartAlbums.count else { return }
    smartAlbums.enumerateObjects { smartAlbum, index, pointer in
      guard index <= smartAlbums.count - 1 else {
        pointer.pointee = true
        return
      }
      if smartAlbum.estimatedAssetCount == NSNotFound {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = Const.predicate(mediaType)
        fetchOptions.sortDescriptors = Const.sortDescriptors
        let smartAlbums = PHAsset.fetchAssets(in: smartAlbum, options: fetchOptions)
        allAlbums.append(
          .init(
            id: smartAlbum.localIdentifier,
            name: smartAlbum.localizedTitle ?? Const.titleText(nil),
            count: smartAlbums.count,
            album: smartAlbums
          )
        )
      }
    }
  }
  
  func getPHAssets(album: PHFetchResult<PHAsset>, completion: @escaping ([PHAsset]) -> Void) {
    guard 0 < album.count else { return }
    var phAssets = [PHAsset]()
    
    album.enumerateObjects { asset, index, stopPointer in
      guard index <= album.count - 1 else {
        stopPointer.pointee = true
        return
      }
      phAssets.append(asset)
    }
    
    completion(phAssets)
  }
  
  func fetchImage(
    asset: PHAsset,
    size: CGSize,
    contentMode: PHImageContentMode,
    completion: @escaping (UIImage) -> Void
  ) {
    let option = PHImageRequestOptions()
    option.isNetworkAccessAllowed = true // for icloud
    option.deliveryMode = .highQualityFormat
    
    self.imageManager.requestImage(
      for: asset,
      targetSize: size,
      contentMode: contentMode,
      options: option
    ) { image, _ in
      guard let image = image else { return }
      completion(image)
    }
  }
}

extension PhotoService: PHPhotoLibraryChangeObserver {
  func photoLibraryDidChange(_ changeInstance: PHChange) {
    self.delegate?.photoLibraryDidChange(changeInstance)
  }
}
